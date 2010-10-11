function y = nondiag(y)
  % y = nondiag(y)
  %
  % returns the non-diagonal elements of a NxN matrix
  
  for ii=1:L(y)
    y(ii,ii) = nan;
  end
  y = nonnans(y);