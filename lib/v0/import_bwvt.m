function data = import_bwvt(directory, filename)
  % data = import_bwvt(directory, filename)
  %
  % function for converting src to a matlab structure
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

%keyboard;  
%% parse filename and directory
% ================================
  
  fn = filename;      
  
  if L(fn) <= 4
    sourcefn  = [fn '.bwvt'];
    destfn    = [fn '.mat'];
  elseif ~strcmp(fn(end+(-4:0)),'.bwvt')
    sourcefn  = [fn '.bwvt'];
    destfn    = [fn '.mat'];
  else
    sourcefn  = fn;
    destfn    = [strip_extension(fn) '.mat'];
  end
  
  directory = fixpath(directory);
  
  % does the file exist?
    if L(dir([directory sourcefn]))==0
      error('file:error','file does not exist');
    end
  
%% import from bwvt
% ==================

  data = struct;
  bwvt = readBWVTfile([directory sourcefn]); 
  
  
%% extract metadata
% ==============================

  % sets
%    try
      params.all = reach(bwvt,'stim.paramVal');
%    catch
%      disp('error');
%      keyboard;
%    end

    [a b c] = unique(params.all','rows');
    params.unique = a';
    params.index  = c';
      
    n.sets = size(params.unique,2);
    n.repeats_per_set = zeros(1,n.sets);
      for ii=1:n.sets
        n.repeats_per_set(ii) = sum(c==ii);
      end
    n.repeats           = max(n.repeats_per_set);
    n.sweeps    = sum(n.repeats_per_set);  


  % time scale
    dt        = 0.040959999071638;  
    maxt.dt   = max(Lincell({bwvt.signal}));
    maxt.ms   = maxt.dt * dt;
    maxt.s    = maxt.ms / 1000;
    
    maxt.by_sweep.dt = Lincell({bwvt.signal});
    maxt.by_sweep.ms = maxt.by_sweep.dt * dt;    

  % set metadata
    params.names = bwvt(1).stim.paramName;
    for ii=1:L(params.names)
      params.names{ii} = make_into_nice_field_name( params.names{ii} );
    end
    n.params = L(params.names);
  
    set_params = struct;
    set_params.allparams = nan * zeros(n.params, n.sets);
    for ii=1:n.sets
      set_params.allparams(:,ii) = bwvt(ii).stim.paramVal(:);
    end
    for ii=1:n.params
      set_params.(params.names{ii}) = set_params.allparams(ii,:);
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

%% extract sweep data 
% ====================

  sweeps = struct;
  current_repeat = ones(1,n.sets);
  progress = 0; 
  fprintf(  '          extracting sweep data');
  fprintf('\n             ');
  
  for kk = 1:L(bwvt);
	 %progress = print_progress(kk,L(bwvt),progress);
    
    fprintf([n2s(kk) '/']);
    if mod(kk,20)==0,   fprintf('\n             '); end

    % metadata
      set_id              = params.index(kk);
      repeat_id           = current_repeat(set_id);
        current_repeat(set_id) = current_repeat(set_id)+1;
      sweep_id            = kk;

      presentation_order  = kk;
      timestamp           = bwvt(kk).timeStamp;
      timevector          = floor(parse_timestamp(timestamp));
      maxt_dt             = maxt.by_sweep.dt(kk);
      maxt_ms             = maxt.by_sweep.ms(kk);      

      sweeps(sweep_id).set_id = set_id;
      sweeps(sweep_id).repeat_id = repeat_id;
      sweeps(sweep_id).sweep_id = sweep_id;
      sweeps(sweep_id).presentation_order = presentation_order;
      sweeps(sweep_id).timestamp = timestamp;
      sweeps(sweep_id).timevector = timevector;
      sweeps(sweep_id).maxt_dt = maxt_dt;
      sweeps(sweep_id).maxt_ms = maxt_ms;

    % set parameters
      st = struct;
      fields = fieldnames(set_params);
      st.(fields{1}) = params.all(:,kk);
      for ff=2:L(fields)
        try
          st.(fields{ff}) = params.all(ff-1,kk);
        catch
          keyboard;
        end
                  %        st.(fields{ff}) = set_params.(fields{ff})(:,set_id);
                  %        keyboard;
                  %         try 
                  %           st.(fields{ff}) = set_params.(fields{ff})(:,kk);
                  %         catch
                  %           keyboard;
                  %         end
      end
      sweeps(sweep_id).set_params = st;
      
    % get spike data
      spikes = get_spikes_from_bwvt_signal( bwvt(kk).signal, 1000/dt); 
      n.spikes  = L(spikes.time);
        if isempty(spikes)
          spikes.time  = [];
          spikes.shape = [];
        end          
        
      % fix any duplicate spikes
        if any(diff(spikes.time)==0)
          [unique_times unique_indices] = unique(spikes.time);
          spikes.time  = spikes.time(:,unique_indices);
          spikes.shape = spikes.shape(:,unique_indices);
          n.spikes = L(spikes.time);
        end          
        
      % put into structure
        sweeps(sweep_id).spikes               = spikes;
        sweeps(sweep_id).spike_t_insweep_ms   =        spikes.time;
        sweeps(sweep_id).spike_t_insweep_dt   = round( spikes.time / dt );
        sweeps(sweep_id).spike_t_absolute_ms  =        spikes.time        + (sweep_id-1)*maxt.ms;
        sweeps(sweep_id).spike_t_absolute_dt  = round( spikes.time / dt ) + (sweep_id-1)*maxt.dt;
        sweeps(sweep_id).spike_shapes         = spikes.shape;
        sweeps(sweep_id).nspikes              = n.spikes;

    % spike metadata
    % ---------------
      sweeps(sweep_id).spike_set_id               = repmat( set_id, 1, n.spikes);
      sweeps(sweep_id).spike_repeat_id            = repmat( repeat_id, 1, n.spikes);
      sweeps(sweep_id).spike_sweep_id             = repmat( sweep_id, 1, n.spikes);
      sweeps(sweep_id).spike_presentation_order   = repmat( presentation_order, 1, n.spikes);


  end
  %fprintf('[done]\n');

%% put into one structure
% ==========================

data = struct;

  % parse filename into bits
    fnshort = sourcefn(1:(end-5));
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
    data.metadata.maxt_by_sweep_ms = [sweeps.maxt_ms];
    data.metadata.maxt_by_sweep_dt = [sweeps.maxt_dt];
    
    data.metadata.n.sets  = n.sets;
    data.metadata.n.repeats_per_set = n.repeats_per_set;
    data.metadata.n.repeats = n.repeats;
    data.metadata.n.sweeps = n.sweeps;
    
    data.metadata.sweeps.sweep_id   = [sweeps.sweep_id];
    data.metadata.sweeps.set_id     = [sweeps.set_id];
    data.metadata.sweeps.repeat_id  = [sweeps.repeat_id];
    
  
  data.set_params   = set_params;
  data.sweeps       = sweeps;
  try
    data.spikes       = sweeps_to_spikes(sweeps);
  catch
    keyboard;
  end

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