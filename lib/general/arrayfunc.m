function c2 = arrayfunc(fun, c, varargin)
  c2 = arrayfun(fun, c, 'uniformoutput', false, varargin{:});
end