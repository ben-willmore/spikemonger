function s = head(s,n)
  if nargin==1
    s = s(1);
  else
    s = s(1:n);
  end
end