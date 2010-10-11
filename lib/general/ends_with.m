function q = ends_with(str,endbit)
  % q = ends_with(str)
  %
  % returns true iff the end of str matches enbit
  
  q = false;
  
  if L(str) < L(endbit)
    return
  end
  
  if ~ isequal(str((L(str) - L(endbit) + 1):L(str)), endbit)
    return
  end
  
  q = true;
  return