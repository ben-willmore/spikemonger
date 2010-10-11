function data = get_sweep_file(varargin)
  % data = get_cell_file(swf)
  % data = get_cell_file(dirs, swf)
  % data = get_cell_file(dirs, swf, type)
  % data = get_cell_file(dirs, timestamp, type)
  % data = get_cell_file(dirs, timestamp, bwvt_source, type)

  
  switch nargin
    
    case 1
      swf = varargin{1};
      data = load(swf.fullname);
      
      
    case 2
      dirs = varargin{1};
      swf  = varargin{2};
      try
        data = load(swf.fullname);
      catch
        filename = [dirs.sweeps swf.timestamp '/' swf.type '.' swf.bwvt_source '.mat'];
        data = load(swf.fullname);
      end
      
      
    case 3
      dirs = varargin{1};      
      type = varargin{3};

      try
        swf  = varargin{2};
        filename = [dirs.sweeps swf.timestamp '/' type '.' swf.bwvt_source '.mat'];
        data = load(filename);
      catch
        timestamp = varargin{2};
        filename = [dirs.sweeps timestamp '/' type '.mat'];
        data = load(filename);
      end
      
      
    case 4
      dirs = varargin{1};
      timestamp   = varargin{2};
      bwvt_source = varargin{3};
      type        = varargin{4};      
      filename = [dirs.sweeps timestamp '/' type '.' bwvt_source '.mat'];
      data = load(filename);
  
      
    otherwise
      error('input:error', 'invalid number of inputs');
  
  end
      
  
  % parse fields
  fields = fieldnames(data);
  if L(fields)==1
    data = data.(fields{1});
  end