function A2_autocut_clusters(dirs, varargin)
  % A2_autocut_clusters(dirs)

warning('off', 'MATLAB:nearlySingularMatrix');

%% prelims
% ===========

% parse dirs
dirs = fix_dirs_struct(dirs);

% title
fprintf_subtitle('(2) clustering');

% terminate if A1 not already done
if ~does_log_exist(dirs, 'A1.finished')
  fprintf_bullet('A1 not done. Skipping A2.\n');
  return;
end

% terminate if all clustering has already been done
if does_log_exist(dirs, 'A2.clustered.training.full') ...
    & does_log_exist(dirs, 'A2.clustered.training.full_no_time') ...
    & does_log_exist(dirs, 'A2.clustered.training.pentatrodes')
  fprintf_bullet('already done.\n');
  return;
end

%% parse input
% =============

% get the sweep list
try
  if nargin==1
    try
      swl = get_event_file(dirs, 'sweep_list');
    catch
      fprintf_bullet('aggregating sweeps...');
      t1 = clock;
      swl = get_sweep_list(dirs);
      save_event_file(dirs, swl, 'sweep_list');
      fprintf_timediff(t1);
    end
  end
catch
  swl = get_event_file(dirs, 'sweep_list');
end



%% cluster, including time
% ============================

%{
fprintf('clustering training data, full with time:\n\n');

% already done?
if does_log_exist(dirs, 'A2.clustered.training.full')
  fprintf_bullet('already done.\n\n');
  
else  
  
  % retrieve candidate event database
  CEs = get_event_file(dirs, 'candidate_events_full');
  fsp = get_event_file(dirs, 'feature_space_full');
  params = CEs.fsp_params;

  % cluster
  t1 = clock;
  clusters = EM_kk(fsp);
  clusters.params = params;

  % save
  save_event_file(dirs, clusters, 'clusters_full');
  create_log(dirs, 'A2.clustered.training.full');
  fprintf(['\n' n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1, clock) ']\n\n']);
end
%}

%% cluster, excluding time
% ==========================
%{

% already done?
fprintf('clustering training data, excluding time:\n');

if does_log_exist(dirs, 'A2.clustered.training.no_time')
  fprintf_bullet('already done.\n');
  
else
  % cluster
  t1 = clock;
  clusters = EM_kk(fsp(:, 1:(size(fsp, 2)-1)));
  clusters.params = params;

  % save
  save_event_file(dirs, clusters, 'clusters_no_time');
  create_log(dirs, 'A2.clustered.training.training.no_time');
  fprintf_title([n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1, clock) ']']);
end
%}

%% cluster, pentatrode time
% ============================

fprintf('clustering training data, pentatrodes with time:\n\n');

% already done?
if does_log_exist(dirs, 'A2.clustered.training.pentatrodes')
  fprintf_bullet('already done.\n\n');
  
else    
  % retrieve feature space
  fsp = get_event_file(dirs, 'feature_space_pentatrodes');

  % add random noise to fsp
  for ii=1:(size(fsp, 2)-1)
    num_of_zeros = sum(fsp(:, ii)==0);
    fsp(fsp(:, ii)==0, ii) = randn(num_of_zeros, 1) * std(fsp(~(fsp(:, ii)==0), ii));
  end
  
  % cluster
  t1 = clock;
  clusters = EM_kk(fsp);
  %clusters.params = params;

  % save
  save_event_file(dirs, clusters, 'clusters_pentatrodes_training');
  create_log(dirs, 'A2.clustered.training.pentatrodes');
  fprintf(['\n' n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1, clock) ']\n\n']);

end


%% re-assign each sweep's CEs to clusters
% ==========================================


fprintf('clustering all data, based on training clusters');

% already done?
if does_log_exist(dirs, 'A2.clustered.pentatrodes')
  fprintf_bullet('\nalready done.\n\n');

else
  
  p = 0; t1 = clock; 
  
  if ~exist('clusters', 'var')
    clusters = get_event_file(dirs, 'clusters_pentatrodes_training');
  end
  
  for ii=1:L(swl)
    p = print_progress(ii, L(swl), p);
    
    % get feature space
    fsp = get_sweep_file(dirs, swl(ii).timestamp, 'fsp');
    n.u = size(fsp, 1);
    n.c = clusters.n_clusters;
    n.d = size(fsp, 2);

    % calculate the respective probabilities for each cluster
    % ----------------------------------------------------------

    % initialise
    logP = nan(n.c, n.u);
    % constant class
    logP(1, :) = log(clusters.W(1));
    % for each cluster
    for cc=2:n.c
      w = clusters.W(cc);
      m = clusters.M(:, cc);
      v = clusters.V(:, :, cc);
      x = (fsp - repmat(m', n.u, 1))';
      logP(cc, :) = -0.5 * sum(x .* (v\x)) - 0.5*logdet(v) - 0.5*n.d*log(2*pi);
    end
    % best cluster assignment
    [junk C] = max(logP);

    % save
    save_sweep_file(dirs, swl(ii).timestamp, C, 'clusters_pentatrodes');

  end
  create_log(dirs, 'A2.clustered.pentatrodes');
  fprintf_timediff(t1);
end


%% delete sweeps
% =================

%fprintf_bullet('cleaning up...');
%rmdir(dirs.sweeps, 's');
%fprintf('[ok]\n');
