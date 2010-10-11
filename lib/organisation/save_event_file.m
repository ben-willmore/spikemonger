function save_event_file(dirs, variable_value, variable_name) %#ok<INUSL>
  % save_event_file(dirs, variable_value, variable_name) 
  %
  % variable_value: the data you're saving
  % variable_name:  what you want it to be called inside the saved file
  %                   eg 'sweep'


  % consistency check
  dirs = fix_dirs_struct(dirs);
  
  % destination
  filename = [dirs.events variable_name '.mat'];
  
  % set the variable according to its name
  eval([variable_name ' = variable_value;']);
  
  % save
  lastwarn('');
  save(filename, variable_name, '-v6');  
  
  % if this failed because the variable was too big
  [a b] = lastwarn;
  if ~isempty(a)
    fprintf('v6 save failed. trying to save in v7.3 (this might take a while)...\n');
    save(filename, variable_name, '-v7.3');
  end