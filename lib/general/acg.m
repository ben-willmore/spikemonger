function y = acg(x)

x = x(:);
m = repmat(x,1,L(x)) - repmat(x',L(x),1);

y = nan( 0.5*(L(x)*(L(x)-1)), 1);
count = 0;
for ii=1:L(x)
  y( count+(1:(L(x)-ii)) ) = m((ii+1):L(x),ii);
  count = count+L(x)-ii;
end