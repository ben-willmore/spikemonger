function str = n2s(num, nchars)
  
  if nargin == 1
    str = num2str(num);
  else
    str = num2str(num, ['%0' num2str(nchars) 'd']);
  end
end