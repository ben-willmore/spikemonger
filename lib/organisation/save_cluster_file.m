function save_cluster_file(dirs, cluster_num, variable_value, variable_name) %#ok<INUSL>
  % save_cluster_file(dirs, cluster_num, variable_value, variable_name)
  %
  % variable_value: the data you're saving
  % variable_name:  what you want it to be called inside the saved file
  %                   eg 'sweep'


  % consistency check
  dirs = fix_dirs_struct(dirs);  
  if ~isfield(dirs,'cluster')
    error('input:error','dirs does not have a cluster field');
  end
  
  % filename
  filename = [dirs.cluster 'cluster.' n2s(cluster_num,2) '.' variable_name '.mat'];
  
  % set the variable according to its name
  eval([variable_name ' = variable_value;']);
  
  % save
  save(filename, variable_name, '-v6');  