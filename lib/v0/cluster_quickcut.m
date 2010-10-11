function data = cluster_quickcut(root_directory, filename, varargin)
  % data = cluster_ui(root_directory, filename)
  % data = cluster_ui(root_directory, filename, 'save_pics')
  %
  % The main UI for quick cluster cutting a given .src file
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)
  
  SPIKEMONGER_VERSION = 'v1.0.0.19';

%% DEFAULT PARAMETERS HERE
% =========================

  clear global features;
  global features; 
  
  n_clusters  = 1;
	stdmax      = 12;
  features    = {'energy','peakmax','peakmin','derivative_max_positive','derivative_max_negative'};

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
  dirs.quickcut     = [dirs.root 'quickcut/'];

% check that stage 2 has been done already
  if get_spikemonger_progress(dirs.root) < 2
    error('stage:incorrect','need to complete earlier stages before cutting clusters');
  end
  
% make quickcut directory (if they don't exist yet)
  warning off MATLAB:MKDIR:DirectoryExists;
    mkdir(dirs.quickcut);
  warning on MATLAB:MKDIR:DirectoryExists;
  
  
%% parse varargin
% ================
  
  save_pics = 0;
  
  if nargin > 2
    for ii=1:L(varargin)
      if isequal('save_pics',varargin{ii})
        save_pics = 1;
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
          rethrow(ME); %error(ME.identifier,ME.message);
        end
      end

    
  % plot
    if save_pics
      sp = plot_cluster_features(data);
        figure(1);
          savefigure(dirs.quickcut, [strip_extension(filename) '.featurespace'], 'png');
        figure(2);
          savefigure(dirs.quickcut, [strip_extension(filename) '.statistics'], 'png');
    end
    

        

%% S: save cluster, then next file

  filename = ask_for_cluster_filename_for_saving(data.metadata.filename);
  save_and_export_cluster( data, filename );


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% functions: reclustering of data
% ====================================



% ---
function save_and_export_cluster( data, filename )
  global dirs SPIKEMONGER_VERSION;

  cluster = data.cluster(1);
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
    cluster.metadata.spikemonger_version = SPIKEMONGER_VERSION;
    cluster.metadata.quickcut = 1;
    
    
  data = export_cluster_to_sets(cluster);
  save([dirs.quickcut filename],'data','-v6');
  
end


% ----
function filename = ask_for_cluster_filename_for_saving(data_fname)
  global dirs;

  files.quickcut = dir([dirs.quickcut '*.mat']);
  
  nc = 1; found_filename = 0;
    while ~found_filename
      filename = [data_fname(1:(end-4)) '_C' num2str(nc) '.mat'];
      switch L(dir([dirs.quickcut filename]))
        case 0
          found_filename = 1;
            fprintf(['     - saving:  ' filename '\n']);              
          return;
        otherwise
          nc = nc+1;
      end
    end
      
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

