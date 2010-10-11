function data = get_root_file(varargin)
  % data = get_root_file(dirs, type)

  
  switch nargin      
      
    case 2
      dirs = varargin{1};
      type = varargin{2};
      filename = [dirs.root type '.mat'];
      data = load(filename);
      
    otherwise
      error('input:error', 'invalid number of inputs');
  
  end
      
  
  % parse fields
  fields = fieldnames(data);
  if L(fields)==1
    data = data.(fields{1});
  end