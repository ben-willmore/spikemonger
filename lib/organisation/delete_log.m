function delete_log(dirs,name)
  % delete_log(dirs,name)
  warning off MATLAB:DELETE:FileNotFound
  try
    delete([dirs.logs name '.log']);
  catch
  end

  warning on MATLAB:DELETE:FileNotFound