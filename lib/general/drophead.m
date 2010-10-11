function s = drophead(s,n)
  if nargin==1
    s = s(2:end);
  else
    s = s((1+n):end);
  end
end