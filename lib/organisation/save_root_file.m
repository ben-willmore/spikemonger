function save_root_file(dirs, variable_value, variable_name) %#ok<INUSL>
  % save_root_file(dirs, variable_value, variable_name) 
  %
  % variable_value: the data you're saving
  % variable_name:  what you want it to be called inside the saved file
  %                   eg 'sweep'


  % consistency check
  dirs = fix_dirs_struct(dirs);
  
  % destination
  filename = [dirs.root variable_name '.mat'];
  
  % set the variable according to its name
  eval([variable_name ' = variable_value;']);
  
  % save
  save(filename, variable_name, '-v6');  