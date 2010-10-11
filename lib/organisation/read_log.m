function log = read_log(dirs,name)
  % log = read_log(dirs,name)
  
  % if there is no log
  if ~does_log_exist(dirs,name)
    warning('log:exist',['log ' name ' does not exist']);
    log = {};
    return;
  end
  
  fid = fopen([dirs.logs name '.log']);
  log = textscan(fid,'%s','delimiter','\n');
  log = log{1};
  fclose(fid);
  
  