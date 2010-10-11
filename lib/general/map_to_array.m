function c2 = map_to_array(fun, c, varargin)
  c2 = arrayfun(fun, c, 'uniformoutput', false, varargin{:});
end