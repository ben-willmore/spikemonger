function q = does_log_exist(dirs,name)
  % q = does_log_exist(dirs,name)
  
  q = ( L(dir([dirs.logs name '.log'])) > 0 );
