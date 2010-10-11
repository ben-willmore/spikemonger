function visible(varargin)
  % visible(obj)
  % visible(obj1, obj2, ...)
  %
  % makes obj(s) visible
  
  for ii=1:nargin
    set(varargin{ii},'visible','on');
  end