function create_log(dirs,name)
  % create_log(dirs,name)
  
  fid = fopen([dirs.logs name '.log'],'w');
  fprintf(fid,['spikemonger version: '  get_sm_version '\n']);
  fprintf(fid,['spikemonger date:    '  get_sm_date '\n']);
  fprintf(fid,['performed at:        '  datestr(now) '\n']);
  fclose(fid);
