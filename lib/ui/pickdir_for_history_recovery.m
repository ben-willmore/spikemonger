function history = pickdir_for_history_recovery(dirs)
  % history = pickdir_for_history_recovery(dirs)

% which pastdirs can we find
pastdirs = getfilelist(dirs.root,'clusters.','prefix');
for ii=1:L(pastdirs)
  pastdirs(ii).history_fullname = [pastdirs(ii).fullname filesep 'history.mat'];
  pastdirs(ii).is_history_there = L(dir(pastdirs(ii).history_fullname))>0;
  pastdirs(ii).n_clusters = L(dir([pastdirs(ii).fullname filesep 'cluster.*data.mat']));
  pastdirs(ii).is_current_cluster = isequal(pastdirs(ii).name, fliplr(get_prefix(drophead(fliplr(dirs.cluster_dest)), filesep)));  
end
pastdirs = pastdirs(~[pastdirs.is_current_cluster] & [pastdirs.is_history_there]);

%% provide option
fprintf_subtitle('which history file do you want?');
for ii=1:L(pastdirs)
  fprintf_bullet(['[' n2s(ii) ']:  ' pastdirs(ii).name '\n']);
  try
    history = load(pastdirs(ii).history_fullname);
    history = history.history;
    fprintf_bullet([n2s(L(history)) ' actions performed\n'],5);
  catch
    fprintf_bullet(['unreadable\n'],5);
  end
  fprintf_bullet([n2s(pastdirs(ii).n_clusters) ' clusters saved\n'],5);
end

fprintf('\n');
fprintf_bullet('[0]:  cancel\n');
fprintf('\n');

whichdir = demandnumberinput('      ----> ',0:L(pastdirs));

if whichdir==0
  history = [];
  return;
else
  history = load(pastdirs(whichdir).history_fullname);
  history = history.history;
end