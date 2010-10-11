function y = normalise_over_bigger_dim(y)
  s = size(y);
  if size(s)>2
    fprintf('normalise_over_bigger_dim currently only supports 2D input - FIXX');
    keyboard;
  end
  
  if s(2)>s(1)
    y = y';
    s = fliplr(s);
    to_flip = 1;
  else
    to_flip = 0;
  end
  
  ym = mean(y);
  ym = repmat(ym,s(1),1);
  ys = std(y);
  ys = repmat(ys,s(1),1);  
  y = (y - ym)./ys;  
  
  if to_flip
    y = y';
  end
end