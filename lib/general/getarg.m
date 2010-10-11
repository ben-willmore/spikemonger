function y = getarg(arglist, argname, default)
  % y = getarg(arglist, argname, default)
  
  y = default;
  for ii = find(cellfun(@(x) isequal(x,argname),arglist))+1
    y = arglist{ii};
  end
  