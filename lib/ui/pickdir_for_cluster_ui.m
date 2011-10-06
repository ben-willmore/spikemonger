function directory = pickdir_for_cluster_ui(rootdir)
  % directory = pickdir(rootdir)
  %
  % UI for picking a directory

  % parse input
    if nargin==0, rootdir=[pwd filesep];
    else rootdir = fixpath(rootdir);
    end

  % directory contents
    files = dir(rootdir);
    dirs  = files([files.isdir]);
    
  % remove invalid directories
    tokeep = true(L(dirs),1);
    for ii=1:L(dirs)
      
      % full name
      dirs(ii).fullname = [rootdir dirs(ii).name filesep];
      
      % remove invalid directories
      switch dirs(ii).name
        case {'.','lib','old','old.disabled','brainware','events','sweep','sweeps',...
            '.temp','clusters_no_time','clusters_time','logs','clusters_pentatrodes', ...
              'raw.f32', 'regressed.f32'}
          tokeep(ii) = false;
      end
      
      % does it contain any clusters
      if L(strfind(dirs(ii).name,'clusters.'))>0
        dirs(ii).n_clusters = L(dir([dirs(ii).fullname 'cluster*data.mat']));
        dirs(ii).is_cluster_dir = true;
      else
        dirs(ii).n_clusters = [];
        dirs(ii).is_cluster_dir = false;
      end      
      
    end
    dirs = dirs(tokeep);
    try
    cluster_dirs = dirs([dirs.is_cluster_dir]);
catch
keyboard
end
    dirs = dirs(~[dirs.is_cluster_dir]);
  
  % display
    fprintf(['\n'...
      '==============================================\n'...
      ' CURRENT DIR: \n'...
      '    ' path_for_fprintf(rootdir) '\n'...
      '==============================================\n']);
    
    % previous cluster sessions
    if L(cluster_dirs)>0
      fprintf(['\n---------------------------------------------------------\n']);
      fprintf(['  previous sessions:\n']);
      for ii=1:L(cluster_dirs)
        fprintf_bullet([cluster_dirs(ii).name '  -  ' n2s(cluster_dirs(ii).n_clusters) ' clusters saved\n']);
      end
      fprintf(['---------------------------------------------------------\n']);
    end
    
    % choose
    fprintf(['\n---------------------------------------------------------\n']);
    fprintf([...
      ' [0]: choose current directory \n'...
      ' \n'...
      ' or navigate to: \n'...
      ]);
    for ii=1:L(dirs)
      fprintf(['    [' num2str(ii) ']: ' dirs(ii).name '\n']);
    end
    fprintf(['---------------------------------------------------------\n']);

  % user option
    todo = demandnumberinput('      ----> ',0:L(dirs));
    switch todo
      case 0
        directory = rootdir;
        return;
      otherwise
        directory = pickdir_for_cluster_ui([rootdir dirs(todo).name filesep]);
        return;
    end
    
end