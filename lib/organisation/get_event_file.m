function data = get_event_file(varargin)
  % data = get_cell_file(dirs, type)

  
  switch nargin      
      
    case 2
      dirs = varargin{1};
      type = varargin{2};
      filename = [dirs.events type '.mat'];
      data = load(filename);
      
    otherwise
      error('input:error', 'invalid number of inputs');
  
  end
      
  
  % parse fields
  fields = fieldnames(data);
  if L(fields)==1
    data = data.(fields{1});
  end