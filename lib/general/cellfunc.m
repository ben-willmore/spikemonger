function c2 = cellfunc(fun, c, varargin)
  if iscell(c)
    c2 = cellfun(fun, c, 'uniformoutput', false, varargin{:});
  else
    c2 = arrayfun(fun, c, 'uniformoutput', false, varargin{:});
  end
end