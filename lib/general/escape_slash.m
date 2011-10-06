function y = escape_slash(x)
  % convert \ to \\ for fprintf
  
  y = regexprep(x, '\\', '\\\');
