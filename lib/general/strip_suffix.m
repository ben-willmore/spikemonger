function str = strip_suffix(str,va1,va2)
  % STRIP_SUFFIX
  %   str = strip_suffix(str)
  %   str = strip_suffix(str,n)
  %   str = strip_suffix(str,delim)
  %   str = strip_suffix(str,delim,n)
  
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
      return;
    end

    pos.lastdot = pos.delim(end);
    if pos.lastdot==1
      error('input:error','string is just an extension!');
    end

    str = str(1:(pos.lastdot-1));
  end
  
end