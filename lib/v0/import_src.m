function data = import_src(directory, filename)
  % data = import_src(directory, filename)
  %
  % function for converting src to a matlab structure
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
%% parse filename and directory
% ================================

  fn = filename;      
  
  if L(fn) <= 4
    sourcefn  = [fn '.src'];
    destfn    = [fn '.mat'];
  elseif ~strcmp(fn(end+(-3:0)),'.src')
    sourcefn  = [fn '.src'];
    destfn    = [fn '.mat'];
  else
    sourcefn  = fn;
    destfn    = [fn(1:(end-4)) '.mat'];
  end
  
  directory = fixpath(directory);
  
  % does the file exist?
    if L(dir([directory sourcefn]))==0
      error('file:error','file does not exist');
    end
  
%% import from src
% ==================

  data = struct;
  src = readSRCfile_nodisp([directory sourcefn]); 
  
%   if strcmp(directory,'expt.1.objects/P08D/')
%     if L(src.sets(95).unassignedSpikes)==5
%       tokeep = find(~(abs([src.sets(95).unassignedSpikes.timeStamp] - 3.9484e+4 + 0.4107) < 0.0001));
%       src.sets(95).unassignedSpikes = src.sets(95).unassignedSpikes(tokeep);
%     end
%   end

  
%% extract metadata
% ==============================

% size of dataset
  n.sets              = L(src.sets);
  n.clusters          = L(src.sets(1).clusters);
  n.repeats_per_set   = Lincell({src.sets.unassignedSpikes});
  n.repeats           = max(n.repeats_per_set);
  n.sweeps    = sum(n.repeats_per_set);
  
% time scale
  dt = 0.040959999071638;  
  maxt.ms   = max([src.sets.sweepLen]); 
  maxt.dt   = ceil( maxt.ms / dt );
  maxt.ms   = maxt.dt * dt;
  
% set metadata
  param.names = src.sets(1).stim.paramName;
  for ii=1:L(param.names)
    param.names{ii} = make_into_nice_field_name( param.names{ii} );
  end
  n.params = L(param.names);
  
  set_params = struct;
  set_params.allparams = nan * zeros(n.params, n.sets);
  for ii=1:n.sets
    set_params.allparams(:,ii) = src.sets(ii).stim.paramVal(:);
  end
  for ii=1:n.params
    set_params.(param.names{ii}) = set_params.allparams(ii,:);
  end
  
% check that there are no duplicates
  n.unique_sets = size(unique(set_params.allparams','rows')',2);
  if ~(n.unique_sets==n.sets)
    to_abort = ask_to_abort(directory,filename);
    switch to_abort
      case 'a'
        error('src:unmerged','src file needs merging in brainware before subsequent processing with spikemonger');      
      case 'r'
        fprintf('\nFix now, then press any key...\n');
        pause;
        data = import_src(directory, filename);
        return;
      case 'i'
    end
  end
      
% sweep presentation order
  initialtime.set_id    = nan * zeros(1, n.sweeps);
  initialtime.repeat_id = nan * zeros(1, n.sweeps);
  initialtime.sweep_id  = nan * zeros(1, n.sweeps);
  initialtime.t         = nan * zeros(1, n.sweeps);
    kk = 0;
    for ii=1:n.sets
      for jj=1:n.repeats_per_set(ii)
        kk = kk+1;
        initialtime.set_id(kk) = ii;
        initialtime.repeat_id(kk) = jj;
        initialtime.sweep_id(kk) = kk;
        initialtime.t(kk) = src.sets(ii).unassignedSpikes(jj).timeStamp;
      end
    end
  initialtime.sorted = sortrows([ initialtime.t' initialtime.set_id' initialtime.repeat_id' initialtime.sweep_id' (1:n.sweeps)'])';
  initialtime.presentation_order = pick( sortrows([initialtime.sorted(5,:)' (1:n.sweeps)'])', '2,:' );
  initialtime.timestamp          = pick( sortrows([initialtime.sorted(5,:)' (1:n.sweeps)' ])', '2,:' );

%% extract sweep data 
% ====================

  sweeps = struct;
  kk = 0;
  for ii=1:n.sets
    for jj=1:n.repeats_per_set(ii)

      % metadata
        set_id              = ii;
        repeat_id           = jj;
                         kk = kk+1;
        sweep_id            = kk;
        
        presentation_order  = initialtime.presentation_order( initialtime.sweep_id == sweep_id );
        timestamp           = initialtime.t( initialtime.sweep_id == sweep_id );        
        
          if L(presentation_order) == 0
            1+1; %#ok<VUNUS>
          end
        
        sweeps(sweep_id).set_id = set_id;
        sweeps(sweep_id).repeat_id = repeat_id;
        sweeps(sweep_id).sweep_id = sweep_id;
        sweeps(sweep_id).presentation_order = presentation_order;
        sweeps(sweep_id).timestamp = timestamp;

      % set parameters
        st = struct;
        fields = fieldnames(set_params);
        for ff=1:L(fields)
          st.(fields{ff}) = set_params.(fields{ff})(:,set_id);
        end
        sweeps(sweep_id).set_params = st;
        
      % spike data
      % -----------
        % get data
          try
            spikes    = [reach( src.sets(ii).clusters, ['sweeps(' num2str(jj) ').spikes'] ) src.sets(ii).unassignedSpikes(jj).spikes];
          catch
            spikes = [];
          end
          n.spikes  = L(spikes);
            if isempty(spikes)
              spikes.time  = [];
              spikes.shape = [];
              spikes.trig2 = [];
            end          
        % sort in time
          [junk time_order] = sort([spikes.time]);        
          spikes = spikes(time_order);
        % fix any duplicate spikes
          if any(diff([spikes.time])==0)
            [unique_times unique_indices] = unique([spikes.time]);
            spikes = spikes(unique_indices);
            n.spikes = L(spikes);
          end          
        % put into structure
          sweeps(sweep_id).spikes               = spikes;
          sweeps(sweep_id).spike_t_insweep_ms   =        [spikes.time];
          sweeps(sweep_id).spike_t_insweep_dt   = round( [spikes.time] / dt );
          sweeps(sweep_id).spike_t_absolute_ms  =        [spikes.time]        + (sweep_id-1)*maxt.ms;
          sweeps(sweep_id).spike_t_absolute_dt  = round( [spikes.time] / dt ) + (sweep_id-1)*maxt.dt;
          sweeps(sweep_id).spike_shapes         = [spikes.shape];
          sweeps(sweep_id).nspikes              = n.spikes;
        
      % spike metadata
      % ---------------
        sweeps(sweep_id).spike_set_id               = repmat( set_id, 1, n.spikes);
        sweeps(sweep_id).spike_repeat_id            = repmat( repeat_id, 1, n.spikes);
        sweeps(sweep_id).spike_sweep_id             = repmat( sweep_id, 1, n.spikes);
        sweeps(sweep_id).spike_presentation_order   = repmat( presentation_order, 1, n.spikes);

      
    end
  end
  
%% put into one structure
% ==========================

data = struct;

  % parse filename into bits
    fnshort = sourcefn(1:(end-4));
    data.metadata.filename = [fnshort '.mat'];
    
    try
      prefix    = fnshort(1:(pick(find(fnshort=='-' | fnshort=='_'),'end')-1));
      data.metadata.prefix = prefix;
    catch
    end
    try
      electrode = str2num(fnshort((pick(find(fnshort=='-' | fnshort=='_'),'end')+1):end));
      data.metadata.electrode = electrode;
    catch
    end
    
  % add metadata
    data.metadata.dt = dt;
    data.metadata.maxt_ms = maxt.ms;
    data.metadata.maxt_dt = maxt.dt;
    data.metadata.n.sets  = n.sets;
    data.metadata.n.repeats_per_set = n.repeats_per_set;
    data.metadata.n.repeats = n.repeats;
    data.metadata.n.sweeps = n.sweeps;
    
    data.metadata.sweeps.sweep_id   = [sweeps.sweep_id];
    data.metadata.sweeps.set_id     = [sweeps.set_id];
    data.metadata.sweeps.repeat_id  = [sweeps.repeat_id];
    
  
  %data.src          = src;
  data.set_params   = set_params;
  data.sweeps       = sweeps;
  data.spikes       = sweeps_to_spikes(sweeps);

  data.spikes.shapes_aligned = getfield(align_shapes(data.spikes.shapes),'aligned'); %#ok<GFLD>
    
end

  
%% functions
% ==============
function to_abort = ask_to_abort(directory,filename)

  fprintf([...
    '********************************************\n' ...
    '  WARNING:\n' ...
    '    there are unmerged sets in the file:\n'...
    '      ' path_for_fprintf(directory) filename '\n'...
    ' \n'...
    '    spikemonger does not have a mechanism\n'...
    '    for merging these; at the moment, you\n'...
    '    need to do this manually in brainware.\n'...
    ' \n'...
    '    sorry.\n'...
    ' \n'...
    '********************************************\n' ...
    '   do you want to:\n'...
    '     [a]: abort \n'...
    '     [r]: retry (but fix in background first) \n'...
    '     [i]: ignore \n'...
  ]);
  to_abort = demandinput('      ----> ',{'a','r','i'});
  
end