function set_errorbar_width(obj,w)
  xdata = get(pick(get(obj,'children'),2),'xdata');
  
  nbars = L(xdata)/9;
  if ~(nbars==round(nbars))
    error('something:wrong','the number of elements of the XData field is not divisible by 9, not sure why');
  end
  
  new_xdata = nan(1,L(xdata));
  for ii=1:nbars
    offset = (ii-1)*9;
    xc    = xdata(offset+1);
    new_xdata(offset+(1:9)) = [xc xc nan xc-w xc+w nan xc-w xc+w nan];
  end 
  set(pick(get(obj,'children'),2),'xdata',new_xdata);
    
end