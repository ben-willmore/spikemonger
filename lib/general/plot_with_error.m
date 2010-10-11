function p = plot_with_error(x,y,e,col)
  % p = plot_with_error(x,y,e)
  % p = plot_with_error(x,y,e,color)
  %
  % simple function for pretty plotting y +/- e as a function of x
  
  if nargin==3
    col = 'b';
  end
  
  hold on;
  
  x = x(:)';
  y = y(:)';
  e = e(:)';  
  minval = min(y-2*e);
  
  % area plot
  p.a = area(x, [y-e; 2*e]', minval, 'facecolor', col, 'linestyle', 'none');
  set(p.a(1),'visible','off');
  p.a = p.a(2);
  set(get(p.a,'children'),'faceAlpha',0.25);
  
  
  % line plot
  p.l = plot(x, y, 'linewidth',4, 'color', col);
  