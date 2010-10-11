function str = get_prefix(str,va1,va2)
  % GET_PREFIX
  %   str = get_prefix(str)
  %   str = get_prefix(str,n)
  %   str = get_prefix(str,delim)
  %   str = get_prefix(str,delim,n)
  
  str = fliplr(str);
  
  if nargin==1
    delim = '.';
    n = 1;
  elseif nargin==2
    if ischar(va1)
      delim = va1;
      n = 1;
    else
      delim = '.';
      n = va1;
    end
  else
    if ischar(va1)
      delim = va1;
      n = va2;
    else
      delim = va2;
      n = va1;
    end
  end

  for ii=1:n
    pos.delim = find(str==delim);
    if L(pos.delim)==0
      str = '';
      return;
    end

    pos.lastdot = pos.delim(end);
    if pos.lastdot==1
      error('input:error','string is just an extension!');
    end

    str = str((pos.lastdot+1):end);
  end
  
  str = fliplr(str);
  
end