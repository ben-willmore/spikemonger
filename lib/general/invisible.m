function invisible(varargin)
  % invisible(obj)
  % invisible(obj1, obj2, ...)
  %
  % makes obj(s) invisible
  
  for ii=1:nargin
    set(varargin{ii},'visible','off');
  end