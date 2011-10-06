function ex = does_sweep_file_exist(dirs, swf, variable_name) %#ok<INUSL>

  % consistency check
  dirs = fix_dirs_struct(dirs);
  
  % parse input
  if isstruct(swf)
    dirs.dest = [dirs.sweeps swf.timestamp filesep];
    try
      filename = [dirs.dest variable_name '.' swf.bwvt_source '.mat'];
    catch
      filename = [dirs.dest variable_name '.' swf.f32_source '.mat'];
    end
  elseif ischar(swf)
    dirs.dest = [dirs.sweeps swf filesep];
    filename = [dirs.dest variable_name '.mat'];
  end  
  
  ex = (L(dir(filename))>0);