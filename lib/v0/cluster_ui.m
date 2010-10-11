function data = cluster_ui(root_directory, filename, varargin)
  % data = cluster_ui(root_directory, filename)
  % data = cluster_ui(root_directory, filename, 'import_clusters', cluster_boundary_directory, cluster_boundary_filenames)
  %
  % The main UI for cluster cutting a given .src file
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)
  
  SPIKEMONGER_VERSION = 'v1.0.0.19';
    

%% DEFAULT PARAMETERS HERE
% =========================

  clear global features allow history;
  global features allow history; 
  
  try
    default_parameters = load('default_parameters.mat');
    n_clusters  = default_parameters.n_clusters;
    stdmax      = default_parameters.stdmax;
    features    = default_parameters.features;
    allow       = default_parameters.allow;
  catch
    n_clusters  = 2;
    stdmax      = 3;
    features    = {'energy','peakmax','peakmin'};
    allow       = struct;
      allow.cluster_naming        = false;
      allow.SU_MU                 = true;
      allow.political_orientation = false;
      allow.comments              = true;
      allow.auto_hmm              = false;
    save('default_parameters.mat','n_clusters','stdmax','features','allow','-v6');
  end

% cutting history
  history = struct('action',{},'parameters',{});
  history(1).action     = 'default parameters';
  history(1).parameters.n_clusters = n_clusters;
  history(1).parameters.stdmax     = stdmax;
  history(1).parameters.features   = features;
  
% show interspike interval on graph
  global show_isi
    try 
      if isempty(show_isi), show_isi=0; end
    catch
      show_isi = 0;
    end
    
% show 
  global show_explainable_variance_in_hmm
    try 
      if isempty(show_explainable_variance_in_hmm), show_explainable_variance_in_hmm=0; end
    catch
      show_explainable_variance_in_hmm = 0;
    end

% zoom level
  global zoomlevel;
  zoomlevel = 10;

 
  
%% prelims
% ==========

% directories etc
  clear global dirs file;
  global dirs file;
  dirs.root         = fixpath(root_directory);
  file.prefix       = strip_extension(filename);
  file.unclustered  = [file.prefix '.mat'];
  dirs.stage2       = [dirs.root 'stage_2_removed_artefacts/'];
  dirs.stage3       = [dirs.root 'stage_3_cluster_boundaries/'];
  dirs.stage4       = [dirs.root 'stage_4_saved_clusters/'];
  dirs.stage5       = [dirs.root 'stage_5_exported_clusters/'];

% check that stage 2 has been done already
  if get_spikemonger_progress(dirs.root) < 2
    error('stage:incorrect','need to complete earlier stages before cutting clusters');
  end
  
% make stages 4&5&6 directory (if they don't exist yet)
  warning off MATLAB:MKDIR:DirectoryExists;
    mkdir(dirs.stage3);
    mkdir(dirs.stage4);
    mkdir(dirs.stage5);
  warning on MATLAB:MKDIR:DirectoryExists;
  
  
%% parse varargin
% ================
  
  global cb;
  cb.import_clusters = 0;
  
  if nargin > 1
    for ii=1:L(varargin)
      if isequal('import_clusters',varargin{ii})
        cb.import_clusters  = 1;
        cb.sourcedir        = varargin{ii+1};
        cb.filenames        = varargin{ii+2};
        cb.n                = L(cb.filenames);        
      end      
    end
  end


%% start by loading default
%     ( or importing a given cluster, if requested)
% =====================================================
    
  % get data file
    data = load([dirs.stage2 file.prefix '.mat']);
    data = data.data;
    
  % check that there actually are spikes
    if size(data.spikes.shapes,2) == 0
      show_zero_spikes_note(file.prefix);
      clear global features allow history;
      return;
    end
    
  % check for .src parsing error introduced prior to v0.07996
    if ~(size(data.spikes.t_insweep_dt,2)==size(data.spikes.sweep_id,2))
      fprintf('fixing parsing error.');
      data = fix_src_parsing_error(data); fprintf('.');
      save([dirs.stage2 file.prefix '.mat'],'data','-v6');
      fprintf('.done\n');
    end
    
  % cut cluster with default parameters, or load imported cluster
    if ~cb.import_clusters 
      try
        data = cluster_cut(data, features, n_clusters, stdmax);
      catch
        ME = lasterror;
        if strcmp(ME.identifier,'stats:kmeans:TooManyClusters') ...
            | strcmp(ME.message,'Output argument "W" (and maybe others) not assigned during call to "/data/spikemonger/lib/EM_GM.m (EM_GM)".') ...
            | strcmp(ME.identifier,'MATLAB:unassignedOutputs') ...
            | strcmp(ME.identifier,'MATLAB:badsubscript')
          show_insufficient_spikes_note(file.prefix);
          clear global features allow history;
          return;
        else
          error(ME.identifier,ME.message);
        end
      end

    elseif cb.import_clusters & (cb.n == 0)
      try
        data = cluster_cut(data, features, n_clusters, stdmax);
      catch
        ME = lasterror;
        if strcmp(ME.identifier,'stats:kmeans:TooManyClusters') ...
            | strcmp(ME.message,'Output argument "W" (and maybe others) not assigned during call to "/data/spikemonger/lib/EM_GM.m (EM_GM)".') ...
            | strcmp(ME.identifier,'MATLAB:unassignedOutputs') ...
            | strcmp(ME.identifier,'MATLAB:badsubscript')
          show_insufficient_spikes_note(file.prefix);
          clear global features allow history;
          return;
        else
          error(ME.identifier,ME.message);
        end
      end

    else
      try
        cluster_boundaries = load([cb.sourcedir cb.filenames{1}]);
        cluster_boundaries = cluster_boundaries.cluster_boundaries;
        data = apply_cluster_boundaries(data,cluster_boundaries);
        
        % adjust history
        history(1).action    = 'import cluster boundaries from bulk list';
        history(1).parameters  = cluster_boundaries;
        history(1).parameters.filename  = [cb.sourcedir cb.filenames{1}];

      catch
        fprintf('could not import cluster boundaries, switching to keyboard mode\n');
        keyboard;
      end
    end
  
  % make backup
    dataold = data;
    
  % plot
    sp = plot_cluster_features(data);
    

        
%% query cycle
% ==============

first_round = true;
continue_clustering = 1;
while continue_clustering
      
  n_clusters  = L(data.cluster)-1;
  stdmax      = data.EM.stdmax;
  features    = data.EM.features;
  
  if first_round & allow.auto_hmm
    clc;
    first_round = false;
    todo = 'h';
  elseif first_round & ~allow.auto_hmm
    clc;
    first_round = false;
    todo = ask_main_question(n_clusters, stdmax, features, file.prefix);    
  else
    todo = ask_main_question(n_clusters, stdmax, features, file.prefix);
  end
  

  switch todo


    % n: change # clusters
    % ----------------------
    case 'n'
      n_clusters = ask_for_n_clusters;
        if n_clusters == 0, continue; end
      dataold = data;
      data    = get_data_reclustered(data,n_clusters,stdmax);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'change # clusters';
        history(L(history)).parameters.n_clusters = n_clusters;
      continue;

    % v: change max std
    % -------------------
    case 'v'
      stdmax = ask_for_stdmax;
        if stdmax == 0, continue; end
      dataold = data;
      data    = get_data_restdmaxed(data,stdmax);      
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'change max std';
        history(L(history)).parameters.stdmax = stdmax;      
      continue;

    % f: change features
    % -------------------
    case 'f'
      features_temp = ask_for_features(features);
        if isequal(features_temp,{'0'}), continue;
        else features = features_temp;
        end
      dataold = data;
      data    = get_data_refeatured(data,features);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'change features';
        history(L(history)).parameters.features = features;
      continue;        

    % m: merge clusters
    % -------------------
    case 'm'
      clusters_to_merge = ask_for_clusters_to_merge(n_clusters);
        if isempty(clusters_to_merge), continue; end
      dataold = data;
      data    = merge_clusters(data,clusters_to_merge);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'merge clusters';
        history(L(history)).parameters.clusters_to_merge = clusters_to_merge;
      continue;

    % d: delete cluster
    % -------------------
    case 'd'
      [cluster_to_delete reclassification] = ask_for_cluster_to_delete(n_clusters);
        if cluster_to_delete == 0, continue; end        
      dataold = data;
      data    = delete_cluster(data,cluster_to_delete,reclassification);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'delete cluster';
        history(L(history)).parameters.cluster_to_delete = cluster_to_delete;
        history(L(history)).parameters.reclassification  = reclassification;
      continue;

    % w: manually adjust weights
    % ----------------------------
    case 'w'
      dataold = data;
      data = manually_adjust_weights(data);
      sp = plot_cluster_features(data);
      
      continue;
      
    % R: reset
    % ---------
    case 'R'
      dataold = data;            
      data = load([dirs.stage2 file.prefix '.mat']);
      data = data.data;
      data = cluster_cut(data, features, n_clusters, stdmax);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action    = 'reset';
        history(L(history)).parameters  = [];
      first_round = true;
      continue;

    % u: undo
    % --------
    case 'u'
      data = dataold;
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action    = 'undo';
        history(L(history)).parameters  = [];
      continue;

    % e: excise repeats
    % ---------------------
    case 'e'
      dataold = data;
      which_repeats     = ask_for_which_repeats(data.metadata.n.repeats);
        if isequal(which_repeats,0), continue; end
      data = excise_repeats(data,which_repeats);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action = 'excise repeats';
        history(L(history)).parameters.which_repeats = which_repeats;
      continue;
      
      
    % h: hidden markov model for catastrophe detection
    % --------------------------------------------------
    case 'h'
      dataold = data;
      data = hmm_on_spike_counts(data);
      sp = plot_cluster_features(data);
      
      continue;
      
      
    % c: plot cross-correlogram
    % --------------------------
    case 'c'
      switch n_clusters
        case {0 1}
          continue;
        case 2
          clusters_to_cc = [1 2];
        otherwise
          clusters_to_cc = ask_for_clusters_to_crosscorrelate(n_clusters);
          if isempty(clusters_to_cc), continue; end
      end
      plot_cross_correlogram(data,clusters_to_cc);


    % r: plot raster
    % --------------------------
    case 'r'
      raster_zoom = ask_for_raster_zoom_mode;
      if any(ismember(raster_zoom,'0')), continue; end
      if any(ismember(raster_zoom,'2'))
        raster_zoom = raster_zoom(~ismember(raster_zoom,'2'));
        fprintf('PLOT 1\n');
        rcs1 = get_raster_conditions(data.metadata,raster_zoom);
        if isequal(rcs1,[]), continue; end
        fprintf('PLOT 2\n');
        rcs2 = get_raster_conditions(data.metadata,raster_zoom);
        if isequal(rcs2,[]), continue; end
        plot_raster(data,raster_zoom,rcs1,rcs2);
      else
        rcs = get_raster_conditions(data.metadata,raster_zoom);
        if isequal(rcs,[]), continue; end
        plot_raster(data,raster_zoom,rcs);
      end
      
    % z: change zoomlevel
    % --------------------------
    case 'z'
      zoomlevel = ask_for_zoomlevel;
      sp = plot_cluster_features(data);
      
      continue;
      

    % k: keyboard mode
    % ---------------------
    case 'a'
      dataold = data;
      advanced_mode(data);
      sp = plot_cluster_features(data);
      
      

    % k: keyboard mode
    % ---------------------
    case 'k'
      show_keyboard_mode_info;
      initial_time = clock;
      keyboard;
        history(L(history)+1).action    = 'keyboard mode';
        history(L(history)).parameters.time_elapsed = timediff(clock,initial_time);
      continue;


    % D: save as default parameters
    % ------------------------------
    case 'D'
      save('default_parameters.mat','n_clusters','stdmax','features','allow','-v6');


    % x: export cluster boundaries
    % -----------------------------
    case 'x'
      filename = ask_for_cb_filename_for_export;
        if strcmp(filename,'0'), continue; end   
      save_cluster_boundaries(filename, data.EM);
        history(L(history)+1).action    = 'export cluster boundaries';
        history(L(history)).parameters = [];


    % i: import cluster boundaries
    % -----------------------------
    case 'i'
      full_filename = ask_for_cb_filename_for_import(dirs.root);
        if strcmp(full_filename,'0'), continue; end
      dataold = data;
      cluster_boundaries = load(full_filename);
      cluster_boundaries = cluster_boundaries.cluster_boundaries;
      data = apply_cluster_boundaries(data,cluster_boundaries);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action    = 'import cluster boundaries';
        history(L(history)).parameters  = cluster_boundaries;
        

    % I: import cluster boundaries from prespecified list
    % ----------------------------------------------------
    case 'I'
      if cb.import_clusters == 0, continue; end
      if cb.n == 0, continue; end
      if cb.n > 1, ok_to_continue = ask_for_which_bulk_cb_to_import; end
      cluster_boundaries = load([cb.sourcedir cb.filenames{1}]);
      cluster_boundaries = cluster_boundaries.cluster_boundaries;
      data = apply_cluster_boundaries(data,cluster_boundaries);
      sp = plot_cluster_features(data);
      
        history(L(history)+1).action    = 'import cluster boundaries from bulk list';
        history(L(history)).parameters  = cluster_boundaries;
        history(L(history)).parameters.filename  = [cb.sourcedir cb.filenames{1}];


    % s: save cluster
    % ----------------
    case 's'
      cluster_to_save = ask_for_cluster_to_save(n_clusters);
        if cluster_to_save == 0, continue; end        
      filename = ask_for_cluster_filename_for_saving(data.metadata.filename);
        if strcmp(filename,'0'), continue; end  
      political_orientation = ask_for_political_orientation;
        if isequal(political_orientation,'0'), continue; end
      cluster_type = ask_for_cluster_type;                  
        if isequal(cluster_type,'0'), continue; end
      comments = add_comments;          
        if strcmp(comments,'0'), continue; end  
      save_and_export_cluster( data, cluster_to_save, comments, cluster_type, political_orientation, filename );
      save_cluster_boundaries(filename, data.EM);      
        history(L(history)+1).action    = 'save cluster';
        history(L(history)).parameters.cluster_to_save = cluster_to_save;
        history(L(history)).parameters.filename = filename;
        history(L(history)).parameters.political_orientation = political_orientation;
        history(L(history)).parameters.cluster_type = cluster_type;
        history(L(history)).parameters.comments = comments;        


    % S: save cluster, then next file
    case 'S'
      cluster_to_save = ask_for_cluster_to_save(n_clusters);
        if cluster_to_save == 0, continue; end        
      filename = ask_for_cluster_filename_for_saving(data.metadata.filename);
        if strcmp(filename,'0'), continue; end  
      political_orientation = ask_for_political_orientation;
        if isequal(political_orientation,'0'), continue; end
      cluster_type = ask_for_cluster_type;                  
        if isequal(cluster_type,'0'), continue; end
      comments = add_comments;          
        if isequal(comments,'0'), continue; end  
      save_and_export_cluster( data, cluster_to_save, comments, cluster_type, political_orientation, filename );
      save_cluster_boundaries(filename, data.EM);      
        history(L(history)+1).action    = 'save cluster';
        history(L(history)).parameters.cluster_to_save = cluster_to_save;
        history(L(history)).parameters.filename = filename;
        history(L(history)).parameters.political_orientation = political_orientation;
        history(L(history)).parameters.cluster_type = cluster_type;
        history(L(history)).parameters.comments = comments;        
      continue_clustering = 0;
      clear global dirs file features;
      break;


    % q: quit
    % --------
    case 'q'
      toquit = ask_to_quit;
        if strcmp(toquit,'n'), continue; end
      continue_clustering = 0;
      clear global dirs file features;
      break;


    % Q: quit --> next penetration
    % -----------------------------        
    case 'Q'
      toquit = ask_to_quit;
        if strcmp(toquit,'n'), continue; end
      continue_clustering = 0;
      clear global dirs file features;
      error('goto:next_penetration','if this message is showing, then could not jump to next penetration');

  end        
        
        
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% functions: reclustering of data
% ====================================

% ----
function data = get_data_reclustered(data,n_clusters,stdmax)
  global dirs file features;
  data = cluster_cut(data, features, n_clusters, stdmax);
end

% ----  
function data = get_data_restdmaxed(data,stdmax)
  global dirs file features;
  n_clusters = L(data.cluster)-1;
  data = change_stdmax(data, stdmax);
end

% ----
function data = get_data_refeatured(data,features)
  global dirs file;
  n_clusters = L(data.cluster)-1;
  stdmax = data.EM.stdmax;
  data = cluster_cut(data, features, n_clusters, stdmax);
end


% ----
function data = merge_clusters(data,clusters_to_merge)
  cc1 = min(clusters_to_merge);
  cc2 = max(clusters_to_merge);
  
  % append spikes from cc2 to cc1
    fields = fieldnames(data.cluster(cc1).spikes);
    for ii=1:L(fields)          
      field = fields{ii};
      data.cluster(cc1).spikes.(field) = [ data.cluster(cc1).spikes.(field) data.cluster(cc2).spikes.(field) ];
    end
    data.nspikes(cc1)         = data.nspikes(cc1) + data.nspikes(cc2);
    data.cluster(cc1).nspikes = data.nspikes(cc1) + data.nspikes(cc2);
  % recalculate statistics
    data.cluster(cc1).psth.count = data.cluster(cc1).psth.count + data.cluster(cc2).psth.count;
    data.cluster(cc1).spikes_per_repeat.count = ...
      data.cluster(cc1).spikes_per_repeat.count + data.cluster(cc2).spikes_per_repeat.count;
    if data.cluster(cc1).nspikes == 0
      data.cluster(cc1).autocorrelogram.tt          = [];
      data.cluster(cc1).autocorrelogram.count       = [];
      data.cluster(cc1).interspike_interval.tt      = [];
      data.cluster(cc1).interspike_interval.count   = [];
    else
      [tt acg isi] = get_autocorrelogram(data.cluster(cc1).spikes,0.5);
      data.cluster(cc1).autocorrelogram.tt    = tt;
      data.cluster(cc1).autocorrelogram.count = acg;
      data.cluster(cc1).interspike_interval.tt    = tt;
      data.cluster(cc1).interspike_interval.count = isi;
    end
  % remove unwanted cluster
    data.cluster = data.cluster([ (1:(cc2-1)) ((cc2+1):end) ]);
    data.nspikes = data.nspikes([ (1:(cc2-1)) ((cc2+1):end) ]);
  % EM
    data.EM.C( data.EM.C == cc2)  = cc1;
    data.EM.C( data.EM.C > cc2)   = data.EM.C( data.EM.C > cc2) - 1;    
  
    
end


% ----
function data = delete_cluster(data,cluster_to_delete,reclassification)
  n_clusters = L(data.cluster)-1;
  switch reclassification
   
    case 'a'  % to unclassified
      % append spikes to unclassified
        fields = fieldnames(data.cluster(1).spikes);
        for ii=1:L(fields)
          field = fields{ii};
          data.cluster(end).spikes.(field) = [...
            data.cluster(end).spikes.(field) ...
            data.cluster(cluster_to_delete).spikes.(field)];
        end
        data.nspikes(end) = data.nspikes(end) + data.nspikes(cluster_to_delete);
        data.cluster(end).nspikes = data.nspikes(end);
      % recalculate statistics
        data.cluster(end).psth.count = data.cluster(end).psth.count + data.cluster(cluster_to_delete).psth.count;
        data.cluster(end).spikes_per_repeat.count = ...
          data.cluster(end).spikes_per_repeat.count + data.cluster(cluster_to_delete).spikes_per_repeat.count;
        if data.cluster(end).nspikes == 0
          data.cluster(end).autocorrelogram.tt          = [];
          data.cluster(end).autocorrelogram.count       = [];
          data.cluster(end).interspike_interval.tt      = [];
          data.cluster(end).interspike_interval.count   = [];
        else
          [tt acg isi] = get_autocorrelogram(data.cluster(end).spikes,0.5);
          data.cluster(end).autocorrelogram.tt    = tt;
          data.cluster(end).autocorrelogram.count = acg;
          data.cluster(end).interspike_interval.tt    = tt;
          data.cluster(end).interspike_interval.count = isi;
        end
      % change EM
        tokeep = setdiff(1:L(data.EM.W), cluster_to_delete);
        data.EM.W = data.EM.W(:,tokeep);
          try
          data.EM.W = data.EM.W / sum(data.EM.W);
          catch
          end
        data.EM.M = data.EM.M(:,tokeep);
        data.EM.V = data.EM.V(:,:,tokeep);
        data.EM.P = data.EM.P(:,tokeep);
        data.EM.NStds   = data.EM.NStds(:,tokeep);
        data.EM.C( data.EM.C == cluster_to_delete)  = n_clusters+1;
        data.EM.C( data.EM.C > cluster_to_delete)   = data.EM.C( data.EM.C > cluster_to_delete) - 1;    
      % remove unwanted cluster
        data.cluster = data.cluster([ (1:(cluster_to_delete-1)) ((cluster_to_delete+1):end) ]);
        data.nspikes = data.nspikes([ (1:(cluster_to_delete-1)) ((cluster_to_delete+1):end) ]);

    case 'b'  % best target
      % change EM
        tokeep = setdiff(1:L(data.EM.W), cluster_to_delete);
        data.EM.W = data.EM.W(:,tokeep);
          try
          data.EM.W = data.EM.W / sum(data.EM.W);
          catch
          end
        data.EM.M = data.EM.M(:,tokeep);
        data.EM.V = data.EM.V(:,:,tokeep);
        data.EM.P = data.EM.P(:,tokeep);
        data.EM.NStds   = data.EM.NStds(:,tokeep);
        for ii=1:size(data.EM.NStds,1)
          [data.EM.best_NStds(ii) junk] = max(data.EM.NStds(ii,:));
        end

      % feign an stdmax change
        stdmax = data.EM.stdmax;
        data.EM.stdmax = -1;
        data.cluster = data.cluster([tokeep L(data.cluster)]);
        data = change_stdmax(data,stdmax);
        
        
  end
end

% ---
function data = excise_repeats(data,which_repeats)
  % remove spikes from those repeats
    tokeep = ~ismember(data.spikes.repeat_id, which_repeats);
    fields = fieldnames(data.spikes);
    for ii=1:L(fields)
      data.spikes.(fields{ii}) = data.spikes.(fields{ii})(:,tokeep);
    end
    
  % excise sweeps
    to_excise.n         = ismember([data.sweeps.repeat_id],which_repeats);
    to_excise.sweep_ids = pick([data.sweeps.sweep_id],(to_excise.n));
      data.excisions.boundaries.sweeps = [...
          data.excisions.boundaries.sweeps; ...
          to_excise.sweep_ids'];
      data.excisions.boundaries.t_relative_dt = [...
          data.excisions.boundaries.t_relative_dt; ...
          repmat([1 data.metadata.maxt_dt],L(to_excise.sweep_ids),1)];
      data.excisions.durations.dt = [...
          data.excisions.durations.dt; ...
          repmat(data.metadata.maxt_dt,L(to_excise.sweep_ids),1)];
      data.excisions.durations.ms = [...
          data.excisions.durations.ms; ...
          repmat(data.metadata.maxt_ms,L(to_excise.sweep_ids),1)];      
    data.excisions = remove_duplicated_excisions(data.excisions,data.metadata.maxt_dt,data.metadata.dt);
  
  % update EM
    data.EM.X = data.EM.X(tokeep,:);
    data.EM.C = data.EM.C(tokeep);
    data.EM.P = data.EM.P(tokeep,:);
    data.EM.best_P = data.EM.best_P(tokeep,:);
    data.EM.NStds = data.EM.NStds(tokeep,:);
    data.EM.best_NStds = data.EM.best_NStds(tokeep,:);      
    
  % feign an stdmax change
    stdmax = data.EM.stdmax;
    data.EM.stdmax = -1;
    data = change_stdmax(data,stdmax);

end


% ---
function save_and_export_cluster( data, cluster_to_save, comments, cluster_type, political_orientation, filename )
  global dirs history SPIKEMONGER_VERSION;

  cluster = data.cluster(cluster_to_save);
    cluster.metadata    = data.metadata;
    cluster.metadata.source_filename = cluster.metadata.filename;
    try
      cluster.metadata.filename = filename;
    catch
      1+1
    end
    cluster.set_params  = data.set_params;
    cluster.excisions   = data.excisions;
    cluster.sweeps      = spikes_to_sweeps(cluster.spikes, data.sweeps);
    cluster.metadata.cluster_type = cluster_type;
    cluster.metadata.clustering_history = history;
    cluster.metadata.spikemonger_version = SPIKEMONGER_VERSION;
    
  if ~isempty(comments)
    cluster.metadata.comments = comments;
  end
  if ~isempty(political_orientation)
    cluster.metadata.political_orientation = political_orientation;
  end
  
  save([dirs.stage4 filename],'cluster','-v6');
  
  data = export_cluster_to_sets(cluster);
  save([dirs.stage5 filename],'data','-v6');
  
end


function plot_cross_correlogram(data,clusters_to_cc)

  MAXT = 25;
  DT = 0.5;

  cc1 = clusters_to_cc(1);
  cc2 = clusters_to_cc(2);
  t1 = data.cluster(cc1).spikes.t_absolute_ms + 200*data.cluster(cc1).spikes.sweep_id;
  t2 = data.cluster(cc2).spikes.t_absolute_ms + 200*data.cluster(cc2).spikes.sweep_id;
  t = [...
    t1                t2; ...
    2*ones(size(t1))  1*ones(size(t2))];
  t = sortrows(t')';
  ta = t(1,:);
  tb = t(2,:);
  
  diffs = [];
  for ii=2:200
    diffst = t(:,ii:end) - t(:,1:(end-ii+1));
     if min(abs(diffst(1,:))) > MAXT
       break;
     end
    diffst = diffst(:, (abs(diffst(1,:)) < (MAXT+DT) & ~(diffst(2,:)==0)) );
    diffst = diffst(1,:) .* diffst(2,:);
    diffs = [diffs diffst];
  end
  
  figure(5);
    hold off;
      xx = (-MAXT:DT:MAXT);
      yy = histc(diffs, xx);
      bar(xx(1:(end-1))+DT/2, yy(1:(end-1)));
    hold on;
      ylims = ylim;
      plot([0 0], [0 ylims(2)],'--','color',[0.75 0.5 0.5]);
    hold off;
    
  xlim((MAXT+DT/2)*[-1 1]);
  xlabel(...
    ['time  [cluster ' num2str(cc1) ' - cluster ' num2str(cc2) ']   (ms)'],...
    'fontweight','bold','fontsize',12); 
  yts = get(gca,'ytick');
  yts = yts(mod(yts,1)==0);
  set(gca,'ytick',yts);
end


% ---
function plot_raster(data,raster_zoom,rcs1,rcs2)

  figure(6); clf; 
  n_rcs = nargin-2;
  
  for rr=1:n_rcs
    ax(rr) = subplot(1,n_rcs,rr);
    if rr==1, rcs=rcs1;
    else      rcs=rcs2;
    end
    
    hold on;
    maxt_ms = data.metadata.maxt_ms;
    n.clusters = L(data.cluster) -1;

    % colours
    colours = { [0.8 0 0], [0 0 0.8], [0.7 0.4 0], [0.2 0.5 0.9], [0.9 0.8 0.4] };
    colours{n.clusters+1} = [0 1 0];

    % horizontal lines
      for ii=0.5:1:(data.metadata.n.sets+0.5)
        plot([0 data.metadata.maxt_ms],ii*[1 1],'-','color',0.8*[1 1 1]);
      end

    % spikes
      for cc=(n.clusters+1):-1:1
        spikes  = data.cluster(cc).spikes;
        tokeep  = ismember(spikes.repeat_id,rcs.repeats);
        xx      = spikes.t_insweep_ms(tokeep);
        yy      = spikes.set_id(tokeep) + (spikes.repeat_id(tokeep)-min(rcs.repeats)+1)/(L(rcs.repeats)+1) - 0.5;
        plot(xx,yy,'.','color',colours{cc});
      end
      ylim([min(rcs.sets) max(rcs.sets)+1]-0.5);
      xlim(rcs.time);
      try 
        h = pan;
        if ismember('t',raster_zoom), set(h,'enable','on');
        else                          set(h,'enable','on','motion','vertical');
        end
      catch end
      
  end
  
  linkaxes(ax);
    
  % reposition
    reposition_gcf(1);
  
end


% ----
function save_cluster_boundaries(filename, EM)  

  global dirs;
  
  if L(filename)<4
    filename = [filename '.mat'];
  elseif ~strcmp(filename(end+(-3:0)),'.mat')
    filename = [filename '.mat'];
  end
  
  cluster_boundaries = rmfield(EM, ...
    {'X','C','P','best_P','NStds','best_NStds','log_likelihood'});
  save([dirs.stage3 filename],'cluster_boundaries','-v6');

end


%% questions
% =============

function todo = ask_main_question(n_clusters, stdmax, features, filename)
  global cb;
  clc;
  
  % source file heading
    title0a = ['||  source file:'];
    title0b = ['||    ' filename];
    if L(title0a) < L(title0b)
      title0a = [title0a repmat(' ',1,L(title0b)-L(title0a))];
    elseif L(title0b) < L(title0a)
      title0b = [title0b repmat(' ',1,L(title0a)-L(title0b))];
    end
    title0a = [title0a '  ||'];
    title0b = [title0b '  ||'];
    title0_line = repmat('=',1,L(title0a));
    fprintf(['\n' title0_line '\n' title0a '\n' title0b '\n' title0_line '\n']);
  
  % if clusters have been bulk-imported
    cb.title_string = '';
    cb.option = '';
    if cb.import_clusters
      switch cb.n
        case 0
          cb.title_string = '     [ bulk cluster import:  <no file available> ]\n';
          cb.option = '';
        case 1
          cb.title_string = ['     [ bulk cluster import:  <' cb.filenames{1} '> ]\n'];
          cb.option = ['  [I]:  import cluster boundaries from \n          <' cb.filenames{1} '> again \n'];
        otherwise
          cb.title_string = ['     [ bulk cluster import:  <' cb.filenames{1} '> ]\n'];
          cb.option = ['  [I]:  import cluster boundaries: from \n          ' cb.sourcedir ' \n'];
      end
    end
    
  % allow certain options only if there are 2+ clusters
  if n_clusters>=2
    w_option = '  [w]:  manually adjust cluster weights \n';
    m_option = '  [m]:  merge clusters \n';
    d_option = '  [d]:  delete cluster \n';
  else
    w_option = '';
    d_option = '';
    m_option = '';
  end
    
  % parameters heading
    title1 = ['||  # clusters = ' num2str(n_clusters)  '  ||'];
    title2 = ['||      stdmax = ' num2str(stdmax)      '  ||'];
    title3 = ['||  # features = ' num2str(L(features)) '  ||'];
    title_line = repmat('=',1,max([L(title1) L(title2) L(title3)]));
    
  % options
    fprintf([...
      cb.title_string ...
      '\n' ...
      title_line '\n' ...
      title1 '\n' ...
      title2 '\n' ...
      title3 '\n' ...
      '======================================================\n' ...
      '  [n]:  change # clusters \n' ...
      '  [v]:  change maximum stdev \n' ...
      '  [f]:  change features \n' ...
      m_option d_option w_option...
      ' \n' ...
      '  [e]:  excise repeats \n'...
      '  [h]:  hidden markov model: catastrophe detection \n'...
      ' \n' ...
      '  [c]:  plot cross-correlogram \n'...
      '  [r]:  plot raster \n'...
      '  [z]:  zoom into plots \n'...
      ' \n' ...
      '  [a]:  advanced features \n'...
      ' \n' ...
      '  [u]:  undo \n' ...
      '  [R]:  reset \n'...
      '  [k]:  keyboard mode \n'...
      '  [D]:  set as default parameters \n'...
      ' \n' ...
      '  [x]:  export cluster boundaries \n' ...
      '  [i]:  import cluster boundaries \n' ...
      cb.option ...
      ' \n' ...
      '  [s]:  save cluster \n' ...
      '  [S]:  save cluster, then go to next file \n' ...
      '  [q]:  quit --> next file\n' ...
      '  [Q]:  quit --> next penetration\n' ...
      '======================================================\n' ...
      ]);  

  possible_answers = {'z','n','v','f','u','r','R','e','c','h','D','x','i','s','S','q','Q','k','a'};
    if L(cb.option) > 1
      possible_answers = [possible_answers 'I'];
    end       
    if L(w_option) > 1
      possible_answers = [possible_answers 'w'];
    end
    if L(d_option) > 1
      possible_answers = [possible_answers 'd'];
    end
    if L(m_option) > 1
      possible_answers = [possible_answers 'm'];
    end

  todo = demandinput('      ----> ',possible_answers);
  
end


% ----
function n_clusters = ask_for_n_clusters
  fprintf([...
    '   --------------------------\n' ...
    '     enter new # clusters:   \n' ...
    '       [0]: cancel           \n' ...
    '       max: 5                \n' ...
    '   --------------------------\n' ...
    ]);
  n_clusters = demandnumberinput('      ----> ',0:5);  
end


% ----
function zoomlevel = ask_for_zoomlevel
  fprintf([...
    '   ------------------------------------\n' ...
    '     zoom to how many standard devs:   \n' ...
    '       [0]: cancel           \n' ...
    '       max: 20               \n' ...
    '   ------------------------------------\n' ...
    ]);
  zoomlevel = demandnumberinput('      ----> ',0:20);  
end


% ----
function stdmax = ask_for_stdmax
  fprintf([...
    '   ---------------------------\n' ...
    '     enter new stdmax:        \n' ...
    '       [0]: cancel            \n' ...
    '   ---------------------------\n' ...
    ]);
  stdmax = demandnumberinput('      ----> ','nonnegative');  
end


% ----
function features = ask_for_features(old_features)
  fprintf([...
    '   ------------------------------\n' ...
    '     enter new set of features:  \n' ...
    '   ------------------------------\n' ...    
    '       [a]: energy \n' ...
    '       [b]: peak max \n' ...
    '       [c]: peak min \n' ...
    '       [d]: area of peak \n' ...
    '       [e]: area of valley \n' ...
    ' \n'...
    '       [f]: max +ve derivative \n'...
    '       [g]: max -ve derivative \n'...
    '       [h]: max abs derivative \n'...
    '       [i]: sum abs derivative \n'...
    ' \n'...
    '     [1-9]: pca components 1-9\n' ...
    ' \n'...
    '       [t]: spike time \n'...
    '       [r]: local firing rate \n'...
    ' \n'...
    '       [0]: keep as is (' lower(get_feature_prefix(old_features)) ')\n' ...
    '   ------------------------------\n' ...
    ]);
  ft = demandcombinationinput('      ----> ',{'0','A','B','C','D','E','F','G','H','I','T','R','a','b','c','d','e','f','g','h','i','t','r','1','2','3','4','5','6','7','8','9'});
  if ismember('0',ft)
    features = {'0'};
  else
    ft = unique(upper(ft));
    features = cell(1,L(ft));
    for ii=1:L(features)
      switch ft(ii)
        case 'A'
          features{ii} = 'energy';
        case 'B'
          features{ii} = 'peakmax';
        case 'C'
          features{ii} = 'peakmin';
        case 'D'
          features{ii} = 'area_peak';
        case 'E'
          features{ii} = 'area_valley';
        case 'F' 
          features{ii} = 'derivative_max_positive';
        case 'G' 
          features{ii} = 'derivative_max_negative';
        case 'H'
          features{ii} = 'derivative_max_absolute';
        case 'I' 
          features{ii} = 'derivative_sum_absolute';
        case '1'
          features{ii} = 'pca1';
        case '2'
          features{ii} = 'pca2';
        case '3'
          features{ii} = 'pca3';
        case '4'
          features{ii} = 'pca4';
        case '5'
          features{ii} = 'pca5';
        case '6'
          features{ii} = 'pca6';
        case '7'
          features{ii} = 'pca7';
        case '8'
          features{ii} = 'pca8';
        case '9'
          features{ii} = 'pca9';
        case 'T'
          features{ii} = 'time';
        case 'R'
          features{ii} = 'local_rate';
      end
    end
  end
end


% ----
function [cluster_to_delete reclassification] = ask_for_cluster_to_delete(n_clusters)
    fprintf([...
      '   --------------------------\n' ...
      '     delete which cluster?   \n' ...
      '       [0]: cancel           \n' ...
      '   --------------------------\n' ...
      ]);
    cluster_to_delete = demandnumberinput('      ----> ',0:n_clusters);     
    if cluster_to_delete == 0
      reclassification = 0;
      return;
    end
  
  fprintf([...
    '   --------------------------------------------------\n' ...
    '     do what with the spikes?                        \n' ...
    '       [0]: cancel                                   \n' ...
    '       [a]: move them all to the unclassified pile   \n' ...
    '       [b]: find the best cluster for them           \n' ...
    '             (if within stdmax of another!)          \n' ...
    '   --------------------------------------------------\n' ...
    ]);
  reclassification = demandinput('      ----> ',{'a','b','0'});
    if reclassification == 0;
      cluster_to_delete = 0;
      return;
    end
end


% ----
function which_repeats = ask_for_which_repeats(n_repeats)
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter starting repeat # \n'...
    '       [1 - ' num2str(n_repeats) '] \n'...
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  startrepeat = demandnumberinput('      ----> ',0:n_repeats); 
    if startrepeat == 0
      which_repeats = 0;
      return;
    end
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter ending repeat # \n'...
    '       [' num2str(startrepeat) ' - ' num2str(n_repeats) '] \n'...    
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  endrepeat = demandnumberinput('      ----> ',[0 startrepeat:n_repeats]); 
    if endrepeat == 0
      which_repeats = 0;
      return;
    end
  which_repeats = startrepeat:endrepeat;
end
  

% ----
function which_sets = ask_for_which_sets(n_sets)
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter starting set # \n'...
    '       [1 - ' num2str(n_sets) '] \n'...
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  startset = demandnumberinput('      ----> ',0:n_sets); 
    if startset == 0
      which_sets = 0;
      return;
    end
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter ending set # \n'...
    '       [' num2str(startset) ' - ' num2str(n_sets) '] \n'...    
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  endset = demandnumberinput('      ----> ',[0 startset:n_sets]); 
    if endset == 0
      which_sets = 0;
      return;
    end
  which_sets = startset:endset;
end


% ----
function which_time = ask_for_which_time(maxt)
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter starting time \n'...
    '         [0 - ' num2str(maxt) '\n' ...
    '   ----------------------------------\n' ...
    ]);
  starttime = demandnumberinput('      ----> ','nonnegative'); 
    if starttime > maxt
      starttime = 0;
    end
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter ending time \n'...
    '         [' num2str(starttime) ' - ' num2str(maxt) '\n' ...    
    '   ----------------------------------\n' ...
    ]);
  endtime = demandnumberinput('      ----> ','nonnegative'); 
    if (endtime <= starttime) | (endtime > maxt)
      endtime = maxt;
    end
  which_time = [starttime endtime];
end


% ---
function keepthis = ask_to_keep_this %#ok<DEFNU>
  fprintf([ ...
    '   -------------------------------------\n' ...
    '     do you want to keep this?  [y/n] \n' ...
    '   -------------------------------------\n' ...
    ]);
  keepthis = demandinput('      ----> ',{'y','n'});
end


% ---
function filename = ask_for_cb_filename_for_export
  global dirs;

  files.stage3 = dir([dirs.stage3 '*.mat']);
  if L(files.stage3) > 0
    fprintf([...
      '   -------------------------------\n' ...
      '     existing filenames: \n' ...
      ]);
    for ii=1:L(files.stage3)
      fprintf(['     - ' files.stage3(ii).name '\n']);
    end
  end
  
    
  fprintf([...
    '   -------------------------------\n' ...
    '     enter desired filename: \n' ...
    '       (no .mat required) \n' ...
    '       [0]: cancel \n' ...
    '   -------------------------------\n' ...
    ]);
  
  filename = input('      ----> ','s');
    if strcmp(filename,'0')
      return;
    end
    
  if L(dir([dirs.stage3 filename '.mat'])) > 0
    fprintf([...
      '   -------------------------------\n' ...
      '     already exists. \n' ...
      '     overwrite?   [y/n] \n' ...
      '   -------------------------------\n' ...
      ]);
    to_overwrite = demandinput('      ----> ',{'y','n'});
    switch to_overwrite
      case 'n'
        filename = '0';
        return;
    end
  end
end
        

% ---
function full_filename = ask_for_cb_filename_for_import(rootdir)

  directory = [fixpath(rootdir) 'stage_3_cluster_boundaries/'];
  files = dir([directory '*.mat']);
  
  fprintf([...
      '   --------------------------------------------------\n' ...
      '     current dir: \n'...
      '        ' directory '\n'...
      '   --------------------------------------------------\n' ...
      '     available files: \n' ...
      ]);
    for ii=1:L(files)
      fprintf(['     [' num2str(ii) ']: ' files(ii).name '\n']);
    end
  fprintf([...
    ' \n'...
    '     [-1]: change directory \n'...
    '     [0]: cancel \n'...
      '   --------------------------------------------------\n' ...
    ]);
  cb_to_load = demandnumberinput('      ----> ',-1:L(files)); 

  switch cb_to_load
    case 0
      full_filename = '0';
      return;

    case -1
      % ask for new dir
        fprintf([...
          '   -------------------------------------------\n' ...
          '     enter new root directory:    \n' ...
          '       (no need for the "stage_3" part) \n'...
          ' \n'...
          '       [enter]: cancel       \n' ...
          '   -------------------------------------------\n' ...
          ]);
        new_root_directory = input('      ----> ','s');
      % cancel option
        if isempty(new_root_directory), 
          full_filename = ask_for_cb_filename_for_import(directory);
          return;
        end
      % does the root directory exist
        new_root_directory = fixpath(new_root_directory);
        n.files_in_root_dir = L(dir(new_root_directory));
        if n.files_in_root_dir == 0
          fprintf('\n*** error: no such root directory. ***\n\n');
          full_filename = ask_for_cb_filename_for_import(directory);
          return;
        end
      % has cluster cutting begun here        
        n.files_in_dir = L(dir([new_root_directory 'stage_3_cluster_boundaries/']));
        if n.files_in_dir == 0
          fprintf('\n*** error: no clusters have been cut for this data set.. ***\n\n');
          full_filename = ask_for_cb_filename_for_import(directory);
          return;
        end
      % if there are possible files to import
        full_filename = ask_for_cb_filename_for_import(new_root_directory);
        return;
      
    otherwise
      full_filename = [directory files(cb_to_load).name];
      
  end
end
  

% ---
function toquit = ask_to_quit
  fprintf([ ...
    '   -------------------------------------\n' ...
    '     quit: are you sure?  [y/n] \n' ...
    '   -------------------------------------\n' ...
    ]);
  toquit = demandinput('      ----> ',{'y','n'});
end


% ----
function cluster_to_save = ask_for_cluster_to_save(n_clusters)
  if n_clusters > 1
    fprintf([...
      '   --------------------------\n' ...
      '     save which cluster?     \n' ...
      '       [0]: cancel           \n' ...
      '   --------------------------\n' ...
      ]);
    cluster_to_save = demandnumberinput('      ----> ',0:n_clusters); 
  else
    fprintf([...
      '   --------------------------\n' ...
      '     saving cluster 1        \n' ...
      '   --------------------------\n' ...
      ]);
    cluster_to_save = 1;
  end
end


% ----
function filename = ask_for_cluster_filename_for_saving(data_fname)
  global dirs allow;

  files.stage4 = dir([dirs.stage4 '*.mat']);
  
  switch allow.cluster_naming
    
    case 1
      if L(files.stage4) > 0
        fprintf([...
          '   -------------------------------\n' ...
          '     existing filenames: \n' ...
          ]);
        for ii=1:L(files.stage4)
          fprintf(['     - ' files.stage4(ii).name '\n']);
        end
      end
      fprintf([...
        '   -------------------------------------------\n' ...
        '     filename will be of the form: \n'...
        '       ' data_fname(1:(end-4)) '_[xxx].mat \n'...
        '   -------------------------------------------\n' ...    
        '     what do you want to put in the [xxx]? \n' ...
        '           [0]: cancel \n' ...
        '       [enter]: default (C1,C2,...) \n' ...
        '   -------------------------------------------\n' ...
        ]);
      filename = input('      ----> ','s');
        if strcmp(filename,'0')
          return;
        elseif strcmp(filename,'d') | isempty(filename)
          nc = 1; found_filename = 0;
          while ~found_filename
            filename = [data_fname(1:(end-4)) '_C' num2str(nc) '.mat'];
            switch L(dir([dirs.stage4 filename]))
              case 0
                found_filename = 1;
                return;
              otherwise
                nc = nc+1;
            end
          end
        end
      if L(dir([dirs.stage4 filename '.mat'])) > 0
        fprintf([...
          '   -------------------------------\n' ...
          '     already exists. \n' ...
          '     overwrite?   [y/n] \n' ...
          '   -------------------------------\n' ...
          ]);
        to_overwrite = demandinput('      ----> ',{'y','n'});
        switch to_overwrite
          case 'n'
            filename = '0';
            return;
        end
      end
      
    case 0
      nc = 1; found_filename = 0;
        while ~found_filename
          filename = [data_fname(1:(end-4)) '_C' num2str(nc) '.mat'];
          switch L(dir([dirs.stage4 filename]))
            case 0
              found_filename = 1;
                fprintf([...
                  '   -------------------------------------------\n' ...
                  '     saving as: \n'...
                  '       ' filename '\n'...
                  '   -------------------------------------------\n' ...    
                  ]);              
              return;
            otherwise
              nc = nc+1;
          end
        end
      
  end % of switch          
end


% ---
function comments = add_comments
  global allow
  if allow.comments
    fprintf([...
      '   -------------------------------------------\n' ...    
      '     add any comments for the cluster here: \n' ...
      '       [leave blank for none] \n' ...
      '       [0]: cancel \n' ...
      '   -------------------------------------------\n' ...
    ]);
    comments = input('      ----> ','s');
  else
    comments = [];
  end
end


% ---
function clusters_to_cc = ask_for_clusters_to_crosscorrelate(n_clusters)
  fprintf([...
    '   -------------------------------------------\n' ...    
    '     pick clusters to cross-correlate... \n' ...
    '       enter cluster #1: \n' ...    
    '         [0]: cancel \n' ...
    '   -------------------------------------------\n' ...
    ]);
  clusters_to_cc = demandnumberinput('      ----> ',0:n_clusters); 
    if clusters_to_cc==0
      clusters_to_cc = [];
      return;
    end
  fprintf([...
    '   -------------------------------------------\n' ...    
    '       enter cluster #2: \n' ...    
    '         [0]: cancel \n' ...
    '   -------------------------------------------\n' ...
    ]);
  clusters_to_cc(2) = demandnumberinput('      ----> ',setdiff(0:n_clusters,clusters_to_cc(1))); 
    if clusters_to_cc(2)==0
      clusters_to_cc = [];
      return;
    end
end


% ---
function cluster_type = ask_for_cluster_type
  global allow
  if allow.SU_MU
    fprintf([...
      '   ------------------------------------\n' ...    
      '     what type of cluster is this?     \n' ...
      '         [1]: SU \n' ...
      '         [2]: MU \n' ...
      '         [3]: ???? \n' ...
      '         [4]: who cares \n'...
      ' \n'...
      '         [0]: cancel \n'...
      '   ------------------------------------\n' ...    
      ]);
    cluster_type_q = demandnumberinput('      ----> ',0:4); 
    switch cluster_type_q
      case 1
        cluster_type = 'SU';
      case 2
        cluster_type = 'MU';
      case 3
        cluster_type = '??';
      case 4
        cluster_type = [];
      case 0
        cluster_type = '0';
    end
  else
    cluster_type = [];
  end
end


% ---
function political_orientation = ask_for_political_orientation
  global allow
  if allow.political_orientation
    fprintf([...
      '   ------------------------------------\n' ...    
      '     has the cluster cutting been     \n' ...
      '         [c]: conservative \n' ...
      '         [l]: liberal \n' ...
      '         [b]: both, there''s no difference \n' ...
      ' \n'...
      '         [f]: who cares \n'...
      ' \n'...
      '         [0]: cancel \n'...
      '   ------------------------------------\n' ...    
      ]);
    political_orientation_q = demandinput('      ----> ',{'c','l','b','f','0'}); 
    switch political_orientation_q
      case 'c'
        political_orientation = 'conservative';
      case 'l'
        political_orientation = 'liberal';
      case 'b'
        political_orientation = 'both';
      case 'f'
        political_orientation = [];
      case 0
        political_orientation = '0';
    end
  else
    political_orientation = [];
  end
end


% ---
function clusters_to_merge = ask_for_clusters_to_merge(n_clusters)
  switch n_clusters
    case {0 1}
      clusters_to_merge = [];
      return;
    case 2
      clusters_to_merge = [1 2];
      return;
  end
  
  fprintf([...
    '   -------------------------------------------\n' ...    
    '     pick clusters to merge... \n' ...
    '       enter cluster #1: \n' ...    
    '         [0]: cancel \n' ...
    '   -------------------------------------------\n' ...
    ]);
  clusters_to_merge = demandnumberinput('      ----> ',0:n_clusters); 
    if clusters_to_merge==0
      clusters_to_merge = [];
      return;
    end
  fprintf([...
    '   -------------------------------------------\n' ...    
    '       enter cluster #2: \n' ...    
    '         [0]: cancel \n' ...
    '   -------------------------------------------\n' ...
    ]);
  clusters_to_merge(2) = demandnumberinput('      ----> ',setdiff(0:n_clusters,clusters_to_merge(1))); 
    if clusters_to_merge(2)==0
      clusters_to_merge = [];
      return;
    end
end


% ---
function raster_zoom = ask_for_raster_zoom_mode
  fprintf([...
    '   -------------------------------------------\n' ...    
    '     show what on raster plot? \n'...
    '        [s]: show only selected sets \n' ...    
    '        [r]: show only selected repeats \n' ...
    '        [t]: show only selected time scale \n'...
    ' \n'...
    '        [2]: compare two rasters side-by-side \n'...
    '        [0]: cancel \n' ...
    ' \n' ...
    '     or just press enter to show all. \n'...
    '   -------------------------------------------\n' ...
    ]);
  raster_zoom = demandcombinationinput('      ----> ',{'s','r','t','0','2'});
end


% ---
function show_keyboard_mode_info
  fprintf([...
    '   -------------------------------------------------\n' ...    
    '     keyboard mode: \n'...
    '        type "return" to go back to spikemonger \n' ...    
    '        type "dbquit" to exit altogether \n' ...
    '   -------------------------------------------------\n' ...    
    ]);
end
    

% ---
function advanced_mode(data)

global allow show_isi show_explainable_variance_in_hmm;
  fprintf([...
    '   -------------------------------------------------------\n' ...
    '     analysis on spike counts: \n'...
    '       [t]: t-test  \n' ...
    '       [v]: variance explainable (sahani-style) \n' ...
    ' \n' ...
    '     saving options: \n'...
    '       [1]: allow cluster naming         ' statusify(allow.cluster_naming) '\n'...
    '       [2]: allow SU/MU                  ' statusify(allow.SU_MU) '\n'...
    '       [3]: allow conservative/liberal   ' statusify(allow.political_orientation) '\n'...
    '       [4]: allow comments               ' statusify(allow.comments) '\n'...
    ' \n' ...
    '     spikemonger options: \n'...
    '       [h]: automatic HMM on startup     ' statusify(allow.auto_hmm) '\n'...
    '       [V]: show var.expl in HMM         ' statusify(show_explainable_variance_in_hmm) '\n'...
    ' \n' ...
    '     plotting options: \n'...
    '       [i]: show interspike intervals    ' statusify(show_isi) '\n'...
    ' \n' ...
    '     [0]: back \n' ...
    '   -------------------------------------------------------\n' ...
    ]);
  todo_advanced = demandinput('      ----> ',{'0','1','2','3','4','h','t','v','i','V'});

  switch todo_advanced   
    case '0'
      return;
      
    case 't'
      t_test_on_spike_counts(data);
      return;
      
    case 'v'
      show_explainable_variance(data.sweeps,data.metadata,data.excisions);
      return;
      
    case 'i'
      show_isi = ~show_isi;
      sp = plot_cluster_features(data);
      
      
    case '1'
      allow.cluster_naming = ~allow.cluster_naming;
      
    case '2'
      allow.SU_MU = ~allow.SU_MU;
      
    case '3'
      allow.political_orientation = ~allow.political_orientation;
      
    case '4'
      allow.comments = ~allow.comments;
      
    case 'h'
      allow.auto_hmm = ~allow.auto_hmm;
      
    case 'V'
      show_explainable_variance_in_hmm = ~show_explainable_variance_in_hmm;

  end
  
  advanced_mode;
  return;
end


% ---
function str = statusify(logicalthing)
  switch logicalthing
    case 1
      str = '[ currently on  ]';
    case 0
      str = '[ currently off ]';
  end
end
      

% ---
function t_test_on_spike_counts(data)
  n_repeats = max(data.spikes.repeat_id);
  
  % ask for boundaries
    fprintf([...
      '==========\n'...
      ' GROUP #1 \n'...
      '==========\n'...
      ]);
    group1 = ask_for_which_repeats(n_repeats);
      if isequal(group1,0), return; end
    fprintf([...
      '==========\n'...
      ' GROUP #2 \n'...
      '==========\n'...
      ]);
    group2 = ask_for_which_repeats(n_repeats);
      if isequal(group2,0), return; end

  % determine scale factor
    repeat_ids                = [data.sweeps([data.excisions.boundaries.sweeps]).repeat_id];
    excision_durations        = data.excisions.durations.dt;
    dur.excised   = zeros(1,data.metadata.n.repeats);
    dur.total     = zeros(1,data.metadata.n.repeats);
    for ii=1:data.metadata.n.repeats,
      dur.excised(ii)   = sum(excision_durations(repeat_ids==ii));
      dur.total(ii)     = data.metadata.maxt_dt * sum([data.sweeps.repeat_id]==ii);
    end
    dur.remaining = dur.total - dur.excised;
    scale_factor = 1 ./ dur.remaining;
    
  % retrieve (scaled) spike counts
    counts1 = zeros(1,L(group1));
    for ii=1:L(counts1)
      jj = group1(ii);
      counts1(ii) = sum(data.spikes.repeat_id == jj) * scale_factor(jj);
    end
    counts2 = zeros(1,L(group2));
    for ii=1:L(counts2)
      jj = group2(ii);
      counts2(ii) = sum(data.spikes.repeat_id == jj) * scale_factor(jj);
    end
    
  % statistical test
    [h p] = ttest2(counts1,counts2);
    
    fprintf([...
      '   -------------------------------------------------------\n' ...
      '     comparing: \n'...
      '       group 1: ' num2str(min(group1)) ' - ' num2str(max(group1)) '\n' ...
      '       group 2: ' num2str(min(group2)) ' - ' num2str(max(group2)) '\n' ...
      ' \n' ...
      '     gives: \n'...
      '       h = ' num2str(h) '\n'...
      '       p = ' num2str(p) '  (' significancestars(p) ')\n' ... 
      '   -------------------------------------------------------\n' ...
      '                               (press <enter> to continue)\n' ...
    ]);
    pause;
    return;
end
    

% ----
function ok_to_continue = ask_for_which_bulk_cb_to_import
  global cb;
  fprintf([...
    '   -------------------------------------------------------\n' ...    
    '      which do you want to load? \n' ...
    ]);
  for ii=1:cb.n
    fprintf(['        [' num2str(ii) ']:  ' cb.filenames{ii} '\n']);
  end
    fprintf(['        [0]: cancel\n'...
    '   -------------------------------------------------------\n']);
  which_to_load = demandnumberinput('      ----> ',0:cb.n); 
  if which_to_load == 0
    ok_to_continue = 0;
    return;
  else
    cb.filenames = cb.filenames([ which_to_load:end 1:(which_to_load-1) ]);
    ok_to_continue = 1;
  end
end


% ----
function data = hmm_on_spike_counts(data,varargin)
  global history show_isi show_explainable_variance_in_hmm;
  X = histc(data.spikes.presentation_order, 0.5+(0:1:(max(data.spikes.presentation_order))));
  datatitle = data.metadata.filename(1:(end-4));
  if nargin==1
    try close(10); catch end
    figure(10); reposition_gcf(1);
  end
  plot_hmm(10,datatitle,X);
  fprintf([...
      '   ----------------------------------------------\n' ...
      '     how many transitions to detect?  \n'...
      '       [1-20] \n'...
      '       [0]: cancel \n' ...
      '   ----------------------------------------------\n' ...
      ]);
  n_transitions = demandnumberinput('      ----> ',0:20);
    if n_transitions==0, 
      try close(10); catch end
      return; 
    end
  [transition_points logL] = hmm(X,n_transitions+1);
    if L(transition_points) ~= n_transitions
      fprintf([...
        'NOTE:\n'...
        '  only ' num2str( L(transition_points)) ' transition points found \n'...
        '  if you want more, try again with a higher number of transitions\n']);
    end
  transition_points = [-0.5; transition_points; L(X)+0.5];  
  plot_hmm(10,datatitle,X,transition_points);
  
  continue_hmm = 1;
  while continue_hmm
    switch n_transitions 
      case 1
        compare_str = [...
          '       [2]: compare 2 regions (plot features) \n'];
        allowable_input = {'n','e','k','K','2','0'};        
      case 2
        compare_str = [...
          '       [2]: compare 2 regions (plot features) \n'...
          '       [3]: compare 3 regions  "   "   "   "\n'];
        allowable_input = {'n','e','k','K','2','3','0'};        
      otherwise
        compare_str = [...
          '       [2]: compare 2 regions (plot features) \n'...
          '       [3]: compare 3 regions  "   "   "   "\n'...
          '       [4]: compare 4 regions  "   "   "   "\n'];
        allowable_input = {'n','e','k','K','2','3','4','0'};
    end

        
    fprintf([...
        '   ----------------------------------------------\n' ...
        '     log likelihood (model) = ' num2str(logL) ' \n'...
        '   ----------------------------------------------\n' ...      
        '       [n]: change # transitions \n'...
        '       [e]: excise region between markers \n'...
        '       [k]: keep region between markers \n'...
        ' \n' ...
        compare_str ...
        ' \n' ...
        '       [K]: keyboard mode \n'...
        '       [0]: return \n' ...
        '   ----------------------------------------------\n' ...
      ]);
    todo = demandinput('      ----> ',allowable_input);
    
    switch todo
      case '0' 
        try close(10); catch end
        return;
        
      case 'n'
        data = hmm_on_spike_counts(data,'noclose');
        continue_hmm = 0; 
        try close(10); catch end
        return;                

      case 'e'
        which_markers = ask_for_which_markers(L(transition_points));
          if isequal(which_markers,0), continue; end
        pos          = [data.sweeps.presentation_order];
        todelete = struct;
        todelete.pos = (pos > transition_points(which_markers(1))) & (pos < transition_points(which_markers(2)));
        todelete.sweep = pick([data.sweeps.sweep_id],todelete.pos);
        data = excise_sweeps(data,todelete.sweep);

          history(L(history)+1).action = 'excise region between markers from HMM';
          history(L(history)).parameters.all_transition_points = transition_points;
          history(L(history)).parameters.selected_transition_points = transition_points(which_markers);

        X = histc(data.spikes.presentation_order, 0.5+(0:1:(max(data.spikes.presentation_order))));
        plot_hmm(10,datatitle,X,transition_points);       
        
      case 'k'
        which_markers = ask_for_which_markers(n_transitions+2);
          if isequal(which_markers,0), continue; end
        pos          = [data.sweeps.presentation_order];
        todelete = struct;
        todelete.pos = (pos < transition_points(which_markers(1))) | (pos > transition_points(which_markers(2)));
        todelete.sweep = pick([data.sweeps.sweep_id],todelete.pos);
        data = excise_sweeps(data,todelete.sweep);

          history(L(history)+1).action = 'keep region between markers from HMM';
          history(L(history)).parameters.all_transition_points = transition_points;
          history(L(history)).parameters.selected_transition_points = transition_points(which_markers);

        X = histc(data.spikes.presentation_order, 0.5+(0:1:(max(data.spikes.presentation_order))));
        plot_hmm(10,datatitle,X,transition_points);
        
      case {'2','3','4'}
        % ask for which markers
          n_regions = str2num(todo);
          which_markers = cell(1,n_regions);
          if (n_transitions+1) > n_regions
            for ii=1:n_regions
              fprintf(['   ----------------------------------\n   REGION ' num2str(ii) ':\n']);
              which_markers{ii} = ask_for_which_markers(n_transitions+2);
              if isequal(which_markers{ii},0), break; end
            end
          else
            for ii=1:n_regions
              which_markers{ii} = [ii ii+1];
            end
          end
          if isequal(which_markers{ii},0), continue; end

        % what needs to be kept/deleted for each subregion
          pos             = [data.sweeps.presentation_order];
          todelete        = struct;
          data_to_compare = cell(1,n_regions+1);
          for ii=1:n_regions
            todelete(ii).pos = (pos < transition_points(which_markers{ii}(1))) | (pos > transition_points(which_markers{ii}(2)));
            todelete(ii).sweep = pick([data.sweeps.sweep_id],todelete(ii).pos);
            data_to_compare{ii} = excise_sweeps(data,todelete(ii).sweep);
          end
        
        % combined subregions
          todelete(n_regions+1).pos = todelete(1).pos;
          for ii=2:n_regions
            todelete(end).pos = todelete(end).pos & todelete(ii).pos;
          end
          todelete(end).sweep = pick([data.sweeps.sweep_id],todelete(end).pos);
          data_to_compare{end} = excise_sweeps(data,todelete(end).sweep);
          
        % plot and display
          if show_explainable_variance_in_hmm
            clc;
            fprintf([...
              '======================\n'...
              ' EXPLAINABLE VARIANCE \n'...
              '======================\n\n'...
              '   ------------------------------------------------\n'...
              ]);
          end
          figure(2); subplot(5+show_isi,1,5+show_isi); ylims = ylim; xlims = xlim;
          for ii=1:n_regions                      
              if show_explainable_variance_in_hmm
                fprintf(['   (' num2str(ii) '):  marker ' num2str(which_markers{ii}(1)) ' - marker ' num2str(which_markers{ii}(2)) '\n']);
                show_explainable_variance(data_to_compare{ii}.sweeps,data_to_compare{ii}.metadata,data_to_compare{ii}.excisions,false);
              end
            sp = plot_cluster_features(data_to_compare{ii},'starting_figure',9+2*ii);
            
            try close(9+2*ii); catch end
            figure(10+2*ii); 
            subplot(5+show_isi,1,5+show_isi); ylim(ylims); xlim(xlims);
            set(gcf,'name',['  marker ' num2str(which_markers{ii}(1)) ' -- marker ' num2str(which_markers{ii}(2))]);
            reposition_gcf(ii);
          end
          if show_explainable_variance_in_hmm
            fprintf(['   COMBINED REGIONS: \n']);
            show_explainable_variance(data_to_compare{end}.sweeps,data_to_compare{end}.metadata,data_to_compare{end}.excisions,false);
          end
          
        % user response
          fprintf(['     (press enter to continue)\n']);
          pause;
          for ii=11:(10+2*n_regions), 
            try close(ii); 
            catch
            end
          end
  
          
      case 'K'
        keyboard;        

        
    end
  end % of while loop
  return;
      
end


% ----
function data = excise_sweeps(data,which_sweeps)
  % remove spikes from those repeats
    tokeep = ~ismember(data.spikes.sweep_id, which_sweeps);
    fields = fieldnames(data.spikes);
    for ii=1:L(fields)
      try
        data.spikes.(fields{ii}) = data.spikes.(fields{ii})(:,tokeep);
      catch
        keyboard;
      end
    end
    
  % excise sweeps
    to_excise.n         = ismember([data.sweeps.sweep_id],which_sweeps);
    to_excise.sweep_ids = sort(which_sweeps);
      data.excisions.boundaries.sweeps = [...
          data.excisions.boundaries.sweeps; ...
          to_excise.sweep_ids'];
      data.excisions.boundaries.t_relative_dt = [...
          data.excisions.boundaries.t_relative_dt; ...
          repmat([1 data.metadata.maxt_dt],L(to_excise.sweep_ids),1)];
      data.excisions.durations.dt = [...
          data.excisions.durations.dt; ...
          repmat(data.metadata.maxt_dt,L(to_excise.sweep_ids),1)];
      data.excisions.durations.ms = [...
          data.excisions.durations.ms; ...
          repmat(data.metadata.maxt_ms,L(to_excise.sweep_ids),1)];      
    data.excisions = remove_duplicated_excisions(data.excisions,data.metadata.maxt_dt,data.metadata.dt);
  
  % update EM
    data.EM.X = data.EM.X(tokeep,:);
    data.EM.C = data.EM.C(tokeep);
    data.EM.P = data.EM.P(tokeep,:);
    data.EM.best_P = data.EM.best_P(tokeep,:);
    data.EM.NStds = data.EM.NStds(tokeep,:);
    data.EM.best_NStds = data.EM.best_NStds(tokeep,:);      
    
  % feign an stdmax change
    stdmax = data.EM.stdmax;
    data.EM.stdmax = -1;
    data = change_stdmax(data,stdmax);
end

% ----
function plot_hmm(fignum, datatitle, X, tps)
  figure(fignum);
  clf; hold on;
  plot(X,'b.'); 
  try
    X_to_show = X;
    if X_to_show(end)==0, X_to_show = X(1:(end-1)); end
    plot(filtfilt([1 2 5 10 12 10 5 2 1]/48,1,X_to_show),'k-','linewidth',2);
  catch
  end
  if nargin==3
    tps = [-0.5; L(X)+0.5];
  end
  for ii=1:L(tps)
    plot(tps(ii)*[1 1],[0 max(X)*1.1],'r--','linewidth',2);    
  end
  for ii=1:L(tps)
    text(...
      tps(ii),max(X)*1.05,num2str(ii),...
      'fontsize',16,'fontweight','bold','horizontalalignment','center',...
      'backgroundcolor',[0.9 0.8 0.3],'edgecolor',[0 0 0],'linewidth',2);
  end
  %xlim([-2 L(X)+2]);
  xlim([pick(find(X > 0),1) pick(find(X > 0),'end')]+[-2 2]);
  ylim([0 max(X)*1.1]);
  
  try set(gcf,'name',datatitle); catch end
  
end


% ----
function which_markers = ask_for_which_markers(n_markers)
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter starting marker # \n'...
    '       [1 - ' num2str(n_markers) '] \n'...
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  startmarker = demandnumberinput('      ----> ',0:n_markers); 
    if startmarker == 0
      which_markers = 0;
      return;
    end
  fprintf([ ...
    '   ----------------------------------\n' ...
    '     enter ending marker # \n'...
    '       [' num2str(startmarker) ' - ' num2str(n_markers) '] \n'...    
    '       [0]: cancel \n'...
    '   ----------------------------------\n' ...
    ]);
  endmarker = demandnumberinput('      ----> ',[0 startmarker:n_markers]); 
    if endmarker == 0
      which_markers = 0;
      return;
    end
  which_markers = [startmarker endmarker];
end



% ----
function show_zero_spikes_note(filename)
  fprintf([...
    '   ----------------------------------\n' ...
    '     no spikes in datafile:\n'...
    '       ' filename '\n'...
    '     press <enter> to continue. \n'...
    '   ----------------------------------\n' ...
    ]);
  pause;
end
    

% ----
function show_insufficient_spikes_note(filename)
  fprintf([...
    '   -----------------------------------------------------\n' ...
    '     insufficient spikes for clustering in datafile:\n'...
    '       ' filename '\n'...
    '     press <enter> to continue. \n'...
    '   -----------------------------------------------------\n' ...
    ]);
  pause;
end


% ----
function rcs = get_raster_conditions(metadata,raster_zoom)
  % default conditions
    which_repeats  = 1:metadata.n.repeats;
    which_sets     = 1:metadata.n.sets;
    which_time     = [0 metadata.maxt_ms];
  % if user requests changed conditions
    raster_zoom = unique(raster_zoom);
    for ii=1:L(raster_zoom)
      switch raster_zoom(ii)
        case 'r'
          which_repeats = ask_for_which_repeats(metadata.n.repeats);
          if isequal(which_repeats,0), rcs=[]; return; end
        case 's'
          which_sets = ask_for_which_sets(metadata.n.sets);
          if isequal(which_sets,0), rcs=[]; return; end
        case 't'
          which_time = ask_for_which_time(metadata.maxt_ms);
          if isequal(which_time,0), rcs=[]; return; end
      end
    end
    rcs = struct;
    rcs.repeats = which_repeats;
    rcs.sets    = which_sets;
    rcs.time    = which_time;
end


% ----
function show_explainable_variance(sweeps,metadata,excisions,show_continue)
  if nargin==3, show_continue = true; end
  % calculate
    dts = [50 35 20 10 5];
    v = struct;
    for ii=1:L(dts)
      vt = sahani_variance_explained(sweeps,metadata,dts(ii),excisions);
      v(ii).m = vt.m;
      v(ii).e = vt.e;
      v(ii).u = vt.u;
      v(ii).noise = vt.noise;
      v(ii).str.e = num2str(100*v(ii).e / v(ii).m,'%3.1f');
      v(ii).str.n = num2str(v(ii).noise,'%3.1f');
      v(ii).str.e = [v(ii).str.e ' %%' repmat(' ',1,12-L(v(ii).str.e))];
      v(ii).str.n = [v(ii).str.n ' x' repmat(' ',1,12-L(v(ii).str.n))];
    end
  % show
  fprintf([...
    '   ------------------------------------------------\n' ...
    '     dt         expl. var         noise level \n'...
    '     -----      ------------      ------------- \n'...
    '     50ms        ' v(1).str.e '    ' v(1).str.n '\n'...
    '     35ms        ' v(2).str.e '    ' v(2).str.n '\n'...
    '     20ms        ' v(3).str.e '    ' v(3).str.n '\n'...
    '     10ms        ' v(4).str.e '    ' v(4).str.n '\n'...
    '      5ms        ' v(5).str.e '    ' v(5).str.n '\n'...
    '   ------------------------------------------------\n' ...
    ]);
  if show_continue
    fprintf([...
      '     press <enter> to continue. \n'...
      '   ------------------------------------------------\n' ...
      ]);
    pause;
  end
end


% ----
function data = fix_src_parsing_error(data)
  n_sweeps = L(data.sweeps);
  for jj=1:n_sweeps
    data.sweeps(jj).nspikes = L(data.sweeps(jj).spikes);
    data.sweeps(jj).spike_set_id             = repmat(data.sweeps(jj).set_id,1,data.sweeps(jj).nspikes);
    data.sweeps(jj).spike_repeat_id          = repmat(data.sweeps(jj).repeat_id,1,data.sweeps(jj).nspikes);
    data.sweeps(jj).spike_sweep_id           = repmat(data.sweeps(jj).sweep_id,1,data.sweeps(jj).nspikes);
    data.sweeps(jj).spike_presentation_order = repmat(data.sweeps(jj).presentation_order,1,data.sweeps(jj).nspikes);
  end
  data.spikes = sweeps_to_spikes(data.sweeps);
  sh = align_shapes(data.spikes.shapes);
  data.spikes.shapes_aligned = sh.aligned;
end


% ----
function data = manually_adjust_weights(data)
  global history;
  % show current weights
    fprintf([...
      '-------------------------------\n'...
      ' current weights: \n']);
    for ii=1:L(data.EM.W)
      fprintf(['    ' num2str(data.EM.W(ii)) '\n']);
    end
    fprintf(['-------------------------------\n']);

  % ask for new weights
    newW = zeros(1,L(data.EM.W));
    for ii=1:(L(data.EM.W)-1)
      fprintf([...
        '  enter weight # ' num2str(ii) ':\n'...
        '    [ min = 0, max = ' num2str(1-sum(newW)) ' ]\n'...
      ]);
      newW(ii) = demandnumberinput('      ----> ',{'min',0,'max',1-sum(newW)});
    end
    newW(end) = 1-sum(newW);

  % show and confirm new weights
    fprintf([...
      '-------------------------------\n'...
      ' new weights: \n']);
    for ii=1:L(newW)
      fprintf(['    ' num2str(newW(ii)) '\n']);
    end
    fprintf(['-------------------------------\n'...
      '  is this ok [y/n]? \n'...
      ]);
    tocontinue = demandinput('      ----> ',{'y','n'});
    
  % enact
    switch tocontinue
      case 'n'
        return;
      case 'y'
        data.EM.W = newW; 
        [data.EM.C data.EM.P data.EM.best_P data.EM.NStds data.EM.best_NStds] = EM_classify(data.EM.X, data.EM.W, data.EM.M, data.EM.V);
        % feign an stdmax change
          stdmax = data.EM.stdmax;
          data.EM.stdmax = -1;
          data = change_stdmax(data,stdmax);
        history(L(history)+1).action = 'manually change cluster weights';
        history(L(history)).parameters.new_weights = newW;

        return;
    end
end