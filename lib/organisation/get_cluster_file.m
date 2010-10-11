function data = get_cluster_file(dirs, cluster_num, type)
  % data = get_cluster_file(dirs, cluster_num, type)

  % consistency check
  dirs = fix_dirs_struct(dirs);    
  if ~isfield(dirs,'cluster')
    error('input:error','dirs does not have a cluster field');
  end

  % load
  filename = [dirs.cluster 'cluster.' n2s(cluster_num,2) '.' type '.mat'];
  data = load(filename);
    
  % parse fields
  fields = fieldnames(data);
  if L(fields)==1
    data = data.(fields{1});
  end