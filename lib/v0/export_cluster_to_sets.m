function data = export_cluster_to_sets(cluster)
  % data = export_cluster_to_sets(cluster)
  %
  % Final function for exporting a cluster and its details into a format
  % that you really want, at the end of the day, for post-sorting analysis.
  % As such, it doesn't really contain much sorting information.
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
%% parameters
% ----------------

  % how many milliseconds of excisions are required before we consider a
  % sweep to be absolute tripe and feed it to the pigs from whence it came
  
    EXCISION_THRESHOLD_FOR_SWEEP_REMOVAL = 1000;

    
%% set up structures
% --------------------
   
  data = struct;
  data.metadata.prefix        = cluster.metadata.prefix;
  data.metadata.electrode     = cluster.metadata.electrode;
  data.metadata.n.sets        = cluster.metadata.n.sets;
  data.metadata.sweeplength   = round(cluster.metadata.maxt_ms);
  
  try
    data.metadata.cluster_type = cluster.metadata.cluster_type;
  catch
  end

  try
    data.metadata.comments = cluster.metadata.comments;
  catch
  end
  
  try
    data.metadata.political_orientation = cluster.metadata.political_orientation;
  catch
  end

  n.sets = cluster.metadata.n.sets;
  
%% segregate into sets
% ========================
  
  ids.set = [cluster.sweeps.set_id];
  ids.repeat = [cluster.sweeps.repeat_id];
  try
    ids.timestamp =  [cluster.sweeps.timestamp];
  catch
  end

  sets = struct;
  params = fieldnames(cluster.set_params);

    
  for ii=1:n.sets
    
    n.repeats = cluster.metadata.n.repeats_per_set(ii);
    
    tokeep    = (cluster.spikes.set_id == ii);
    n.spikes  = sum(tokeep);
    repeat_id = cluster.spikes.repeat_id(tokeep);
    time      = cluster.spikes.t_insweep_ms(tokeep);
    
    sets(ii).spikes.t = time;
    sets(ii).spikes.repeat_id = repeat_id;
    
    for jj=1:n.repeats
      sets(ii).repeats(jj).t = sort(time(repeat_id==jj));
      sets(ii).repeats(jj).n_spikes = sum(repeat_id==jj);
      try
        sets(ii).repeats(jj).timestamp = ids.timestamp((ids.set == ii) & (ids.repeat == jj));
      catch
        fprintf('error in export_cluster_to_sets -- going to keyboard');
        keyboard;
      end
    end
      
    spt = cluster.sweeps(pick(find([cluster.sweeps.set_id]==ii),1)).set_params;
    for jj=1:L(params)
      sets(ii).stim_params.(params{jj}) = spt.(params{jj});
    end

  end
  
  data.set = sets; 


%% excisions: 
% ============

% if excision is longer than threshold (defined above), 
% then cut out that repeat altogether. 

excisions = struct;
excisions.sweep_id    = cluster.excisions.boundaries.sweeps';
excisions.set_id      = cluster.metadata.sweeps.set_id( excisions.sweep_id );
excisions.repeat_id   = cluster.metadata.sweeps.repeat_id( excisions.sweep_id );
excisions.boundaries  = ((cluster.excisions.boundaries.t_relative_dt - 1) * cluster.metadata.dt)';
excisions.durations   = diff(excisions.boundaries);

tokeep = excisions.durations > EXCISION_THRESHOLD_FOR_SWEEP_REMOVAL;
fields = fieldnames(excisions);
for ii=1:L(fields)
  excisions.(fields{ii}) = excisions.(fields{ii})(:,tokeep);
end

% excise
  for ii=L(excisions.set_id):-1:1
    set_id = excisions.set_id(ii);
    repeat_id = excisions.repeat_id(ii);
    
    repeats_to_keep = setdiff( 1:L(data.set(set_id).repeats), repeat_id );
    data.set(set_id).repeats = data.set(set_id).repeats(repeats_to_keep);
    
    sr = data.set(set_id).spikes.repeat_id;
    sr( sr > repeat_id ) = sr( sr > repeat_id ) - 1;
    data.set(set_id).spikes.repeat_id = sr;
  end
  
data.metadata.n.repeats_per_set = Lincell({data.set.repeats});
