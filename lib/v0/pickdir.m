function directory = pickdir(rootdir)
  % directory = pickdir(rootdir)
  %
  % UI for picking a directory

  % parse input
    if nargin==0, rootdir=[pwd '/'];
    else rootdir = fixpath(rootdir);
    end

  % directory contents
    files = dir(rootdir);
    dirs  = files([files.isdir]);
    
  % remove invalid directories
    tokeep = true(L(dirs),1);
    for ii=1:L(dirs)
      switch dirs(ii).name
        case {'.','lib','old','clusterc','brainware','stage_1_converted_srcs','stage_2_removed_artefacts','stage_3_cluster_boundaries','stage_4_saved_clusters','stage_5_exported_clusters'}
          tokeep(ii) = false;
      end
    end
    dirs = dirs(tokeep);
  
  % display
    fprintf(['\n'...
      '==============================================\n'...
      ' CURRENT DIR: \n'...
      '    ' path_for_fprintf(rootdir) '\n'...
      '==============================================\n'...
      ' [0]: choose current directory \n'...
      ' \n'...
      ' or navigate to: \n'...
      ]);
    for ii=1:L(dirs)
      fprintf(['    [' num2str(ii) ']: ' dirs(ii).name '\n']);
    end
    fprintf(['---------------------------------\n']);

  % user option
    todo = demandnumberinput('      ----> ',0:L(dirs));
    switch todo
      case 0
        directory = rootdir;
        return;
      otherwise
        directory = pickdir([rootdir dirs(todo).name '/']);
        return;
    end
    
end