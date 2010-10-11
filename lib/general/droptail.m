function s = droptail(s,n)
  if nargin==1
    s = s(1:(end-1));
  else
    s = s(1:(end-n));
  end
end