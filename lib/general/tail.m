function s = tail(s,n)
  if nargin==1
    s = s(end);
  else
    s = s((end-n+1):end);
  end
end