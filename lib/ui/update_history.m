function history = update_history(history,todo,dirs)
  % history = update_history(todo);
  
  
  % do not update history if todo is empty
  if isempty(todo)
    return;
  end
  
  switch todo{1}
  % do not update history if we just asked for a plot or something
  % miscellaneous
    case {'0','1','2','3','h','H','k','p'}
      return;
  
    case 'u'
      history = history(1:(end-1));
      
    otherwise
      % update
      history{L(history)+1} = todo;
  end
  
  % save, just in case
  save([dirs.cluster_dest 'history.mat'],'history','-v6');