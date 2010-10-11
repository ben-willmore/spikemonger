function spikes = get_candidate_events_from_signal(signal,fs,method)
  % GET_CANDIDATE_EVENTS_FROM_SIGNAL
  %   signal = get_candidate_events_from_signal(signal,fs)
  %   signal = get_candidate_events_from_signal(signal,fs,'original')
  %   signal = get_candidate_events_from_signal(signal,fs,'awake')

  if nargin==1
    dt = 0.040959999071638; % ms
    fs = 1000/dt;           % Hz
  end
  
  if nargin<3
    method = 'awake';
  end
  
%% filter?
% =========

% filter?
to_filter = false;
if nargin>2
  if isequal('filter',method)
    
    % construct filter
    Wp = [300 3000];
    n = 6;
    [z,p,k] = ellip(n, 0.01, 80, Wp/(fs/2));
    [sos,g] = zp2sos(z,p,k);
    Hd = dfilt.df2tsos(sos,g);
    
    % padding
    signal = filtfilthd(Hd,signal);
  end
end
     
%% detect events that cross threshold
% =====================================

switch method
    
  % ---------------
  % single block
  % ---------------
  
  case 'original'
    
    % parameters
    %signal = signal / std(signal(:));
    signal = signal / median(abs(signal) / 0.6745);
    t.to_keep = -14:25;
    
    % find threshold crossings
    THRESHOLD = 4; %3.5 * 1;
    smp = struct;
    smp.below_thresh = find(signal < -THRESHOLD);
    if L(smp.below_thresh)==0
      spikes = struct;
      spikes.time_ms = zeros(1,0);
      spikes.time_smp = zeros(1,0);
      return;
    end
    smp.cross_thresh = smp.below_thresh([0; diff(smp.below_thresh)]~=1);
    
    % remove those too close to the start and end of the signal
    within_range = ...
      (smp.cross_thresh + 19 <= L(signal));
    smp.cross_thresh = smp.cross_thresh(within_range);
    if L(smp.cross_thresh)==0
      spikes = struct;
      spikes.time_ms = zeros(1,0);
      spikes.time_smp = zeros(1,0);
      return;
    end
    
    % spike times
    t.cross_thresh = smp.cross_thresh/fs;
    
    % minimum time
    try
      [a b] = min(signal(repmat(smp.cross_thresh,1,20) + repmat(0:19,L(smp.cross_thresh),1)),[],2);
      smp.abs_minimum = smp.cross_thresh + b;
    catch
      fprintf('failed min\n');
      keyboard;
    end
    
    % remove those too close to the start and end of the signal
    within_range = ...
      (smp.abs_minimum+min(t.to_keep)>=1) ...
      & (smp.abs_minimum+max(t.to_keep)<=L(signal));
    smp.abs_minimum = smp.abs_minimum(within_range);
    
    % remove duplicates
    smp.abs_minimum = unique(smp.abs_minimum);
    t.abs_minimum = smp.abs_minimum/fs;
        
  
  % ------------------
  % separate blocks
  % ------------------
  
  case 'awake'
    chunk_length = round(fs/2);
    ni = max(ceil(L(signal)/chunk_length),1);    
    sp = cell(1,ni);
    for ii = 1:ni
      ti = round(chunk_length*(ii-1) + 1);
      tf = min(round(chunk_length*ii), L(signal));
      spt = get_candidate_events_from_signal( signal(ti:tf), fs, 'original' );
      try
      spt.time_ms  = spt.time_ms + chunk_length/fs*1000*(ii-1);
      catch
        keyboard;
      end
      spt.time_smp = spt.time_smp + chunk_length*(ii-1);
      sp{ii} = spt;
    end
    sp = cell2mat(sp);
    spikes = struct;
    try
      spikes.time_ms  = [sp.time_ms];
      spikes.time_smp = [sp.time_smp];
    catch
      spikes.time_ms = [];
      spikes.time_smp = [];
    end
    return;
    
    
end

    
%% output 
% =========
  
  spikes = struct;
  spikes.time_ms = t.abs_minimum' * 1000;
  spikes.time_smp = smp.abs_minimum';   

  
end