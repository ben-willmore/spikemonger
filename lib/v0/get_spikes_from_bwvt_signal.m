function spikes = get_spikes_from_bwvt_signal(signal,fs,method)
  % GET_SPIKES_FROM_BWVT_SIGNAL
  %   signal = get_spikes_from_bwvt_signal(signal,fs)

  if nargin==2
    method = 'original';
     method = 'awake';
  end
  
 
  
  
%% filter between 300Hz and 3kHz
% =================================

if ~isequal(method,'original_no_filtering')
  % construct filter
    Wp = [300 3000];
    n = 6;
    [z,p,k] = ellip(n, 0.01, 80, Wp/(fs/2));
    [sos,g] = zp2sos(z,p,k);
    Hd = dfilt.df2tsos(sos,g);  

  % padding
    signal = filtfilthd(Hd,signal);
end

     
%% detect events that cross threshold
% ================================
    
switch method
  case {'original','original_no_filtering'}
 
    % parameters
    signal = signal / std(signal(:));
      t.to_keep = -14:25;    

    % find threshold crossings
      THRESHOLD = 3.5 * 1;
      pos = struct;    
      pos.below_thresh = find(signal < -THRESHOLD);    
     if L(pos.below_thresh)==0
       spikes = struct;
       spikes.time = zeros(1,0);
       spikes.shape = zeros(40,0);
       return;
     end
      pos.cross_thresh = pos.below_thresh([0; diff(pos.below_thresh)]~=1);    

    % remove those too close to the start and end of the signal
      within_range = ...
        (pos.cross_thresh + 19 <= L(signal));
      pos.cross_thresh = pos.cross_thresh(within_range);
      if L(pos.cross_thresh)==0
        spikes = struct;
        spikes.time = zeros(1,0);
        spikes.shape = zeros(40,0);
        return;
     end

    % spike times
      t.cross_thresh = pos.cross_thresh/fs;   

    % minimum time
      try
        [a b] = min(signal(repmat(pos.cross_thresh,1,20) + repmat(0:19,L(pos.cross_thresh),1)),[],2);
        pos.abs_minimum = pos.cross_thresh + b;
      catch
        fprintf('failed min\n');
        keyboard;
      end

    % remove those too close to the start and end of the signal
      within_range = ...
          (pos.abs_minimum+min(t.to_keep)>=1) ...
        & (pos.abs_minimum+max(t.to_keep)<=L(signal));
      pos.abs_minimum = pos.abs_minimum(within_range);

    % remove duplicates
      pos.abs_minimum = unique(pos.abs_minimum);
      t.abs_minimum = pos.abs_minimum/fs;

    % shapes    
      try
        shapes = signal(repmat(pos.abs_minimum,1,L(t.to_keep)) + repmat(t.to_keep,L(pos.abs_minimum),1));
      catch
        fprintf('failed shapes\n');
        keyboard;
      end

    
  case 'movingmartin'
    % get spike times
    [median,spiketimes]=spikedetect(signal,100,4,1,fs,0,4.5);
    spiketimes = spiketimes(spiketimes < L(signal)-25);
    pos.abs_minimum = spiketimes;
    t.abs_minimum = spiketimes / fs;
    t.to_keep = -14:25;    
    
    try
      shapes = signal(repmat(pos.abs_minimum,1,L(t.to_keep)) + repmat(t.to_keep,L(pos.abs_minimum),1));
    catch
      fprintf('failed shapes\n');
      keyboard;
    end
    
    
  case 'awake'
    chunk_length = round(fs/2);
    ni = floor(L(signal)/chunk_length);
    sp = cell(1,ni);
    for ii = 1:ni
      ti = round(chunk_length*(ii-1) + 1);
      tf = min(round(chunk_length*ii), L(signal));
      spt = get_spikes_from_bwvt_signal( signal(ti:tf), fs, 'original_no_filtering' );
      spt.time = spt.time + chunk_length/fs*1000*(ii-1);
      sp{ii} = spt;
    end
    sp = cell2mat(sp);
    spikes = struct;
    spikes.time = [sp.time];
    spikes.shape = [sp.shape];
    return;
    
    %%
end
    
    
%% output format
  
  spikes = struct;
  spikes.time = t.abs_minimum' * 1000;
  spikes.shape = shapes' * 8;
   
  if size(spikes.shape,1)==1, spikes.shape = spikes.shape'; end

  
end