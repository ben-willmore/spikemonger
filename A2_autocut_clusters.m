function A2_autocut_clusters(dirs, varargin)
  % A2_autocut_clusters(dirs)

%% prelims
% ===========

% parse dirs
dirs = fix_dirs_struct(dirs);

% title
fprintf_subtitle('(2) clustering');

% terminate if all clustering has already been done
if does_log_exist(dirs,'A2.clustered.full') ...
    & does_log_exist(dirs,'A2.clustered.full_no_time') ...
    & does_log_exist(dirs,'A2.clustered.pentatrodes')
  fprintf_bullet('already done.\n');
  return;
end

%% parse input
% =============

% get the sweep list
try
  if nargin==1
    try
      swl = get_event_file(dirs,'sweep_list');
    catch
      fprintf_bullet('aggregating sweeps...');
      t1 = clock;
      swl = get_sweep_list(dirs);
      save_event_file(dirs,swl,'sweep_list');
      fprintf_timediff(t1);
    end
  end
catch
  swl = get_event_file(dirs,'sweep_list');
end



%% cluster, including time
% ============================

%{
fprintf('clustering, full with time:\n\n');

% already done?
if does_log_exist(dirs,'A2.clustered.full')
  fprintf_bullet('already done.\n\n');
  
else  
  
  % retrieve candidate event database
  CEs = get_event_file(dirs,'candidate_events_full');
  fsp = get_event_file(dirs,'feature_space_full');
  params = CEs.fsp_params;

  % cluster
  t1 = clock;
  clusters = EM_kk(fsp);
  clusters.params = params;

  % save
  save_event_file(dirs,clusters,'clusters_full');
  create_log(dirs,'A2.clustered.full');
  fprintf(['\n' n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1,clock) ']\n\n']);
end
%}

%% cluster, excluding time
% ==========================
%{

% already done?
fprintf('clustering, excluding time:\n');

if does_log_exist(dirs,'A2.clustered.no_time')
  fprintf_bullet('already done.\n');
  
else
  % cluster
  t1 = clock;
  clusters = EM_kk(fsp(:,1:(size(fsp,2)-1)));
  clusters.params = params;

  % save
  save_event_file(dirs,clusters,'clusters_no_time');
  create_log(dirs,'A2.clustered.no_time');
  fprintf_title([n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1,clock) ']']);
end
%}

%% cluster, pentatrode time
% ========================

fprintf('clustering, pentatrodes with time:\n\n');

% already done?
if does_log_exist(dirs,'A2.clustered.pentatrodes')
  fprintf_bullet('already done.\n\n');
  
else    
  % retrieve feature space
  fsp = get_event_file(dirs,'feature_space_pentatrodes');

  % add random noise to fsp
  for ii=1:(size(fsp,2)-1)
    num_of_zeros = sum(fsp(:,ii)==0);
    fsp(fsp(:,ii)==0,ii) = randn(num_of_zeros,1) * std(fsp(~(fsp(:,ii)==0),ii));
  end
  
  % cluster
  t1 = clock;
  clusters = EM_kk(fsp);
  %clusters.params = params;

  % save
  save_event_file(dirs,clusters,'clusters_pentatrodes');
  create_log(dirs,'A2.clustered.pentatrodes');
  fprintf(['\n' n2s(clusters.n_clusters) ' clusters found.  [' timediff(t1,clock) ']\n\n']);

end
