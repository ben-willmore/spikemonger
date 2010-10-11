function C = cluster_save(C,id,dirs)
  % C = cluster_save(C,id,dirs)
  %
  % helper for cluster_ui
  
  % if more than one id provided
  if L(id)>1
    id = sort(id,'descend');
    for ii=1:L(id)      
      C = cluster_save(C,id(ii),dirs);
    end
    return;
  end
  
  fprintf_bullet(['saving cluster ' n2s(id) '...']);
  
  % check how many clusters saved in that directory
  dirs.cluster = dirs.cluster_dest;
  files = dir([dirs.cluster 'cluster.*.data*.mat']);
  n.done = L(files);
  
  % make this cluster the next one
  n.this = n.done + 1;
  
  % save the bits
  save_cluster_file(dirs, n.this, C.fsp{id}, 'event_fsp_examples');
  save_cluster_file(dirs, n.this, C.sh{id}, 'event_shape_examples');
  save_cluster_file(dirs, n.this, C.sh_mean{id}, 'event_shape_mean');
  save_cluster_file(dirs, n.this, C.psth(id), 'psth_all_sets');
  save_cluster_file(dirs, n.this, C.acgs(id), 'ACGs');
  save_cluster_file(dirs, n.this, C.isis(id), 'ISIs');
  save_cluster_file(dirs, n.this, C.sve(id), 'sahani_variance_explainable');
  save_cluster_file(dirs, n.this, C.data(id), 'data');
  save_cluster_file(dirs, n.this, C.sweep_count{id}, 'sweep_spike_count');
  
  % print logs
  logs = struct;
  logfiles = getfilelist(dirs.logs,'log');
  for ii=1:L(logfiles)
    try
      name = strip_suffix(logfiles(ii).name);
      logs.(make_into_nice_field_name(name)) = read_log(dirs, name);
    catch
    end
  end  
  logs.this_cluster = {['spikemonger version: '  get_sm_version]; ...
   ['spikemonger date:    '  get_sm_date]; ...
   ['performed at:        '  datestr(now)]};
  save_cluster_file(dirs, n.this, logs, 'logs');


  % update C by deleting this one
  C = cluster_delete(C,id);
  fprintf('[ok]\n');