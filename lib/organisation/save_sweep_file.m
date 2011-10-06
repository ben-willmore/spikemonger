function save_sweep_file(dirs, swf, variable_value, variable_name) %#ok<INUSL>
  % save_sm_file(dirs, swf, variable_value, variable_name) 
  % save_sm_file(dirs, timestamp, variable_value, variable_name) 
  %
  % prefix:   eg 'P03.noise.E03'
  % filename: eg 'data.i.need.later' or 'data.i.need.later.mat'
  % variable_value: the data you're saving
  % variable_name:  what you want it to be called inside the saved file
  %                   eg 'sweep'


  % consistency check
  dirs = fix_dirs_struct(dirs);
  
  % parse input
  if isstruct(swf)
    dirs.dest = [dirs.sweeps swf.timestamp filesep];
    mkdir_nowarning(dirs.dest);
    try
      filename = [dirs.dest variable_name '.' swf.bwvt_source '.mat'];
    catch
      filename = [dirs.dest variable_name '.' swf.f32_source '.mat'];
    end
    
  elseif ischar(swf)
    dirs.dest = [dirs.sweeps swf filesep];
    mkdir_nowarning(dirs.dest);
    filename = [dirs.dest variable_name '.mat'];
  end  
  
  % set the variable according to its name
  eval([variable_name ' = variable_value;']);
  
  % save
  save(filename, variable_name, '-v6');  