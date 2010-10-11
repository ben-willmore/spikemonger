function set_height_centred(obj,h)

  pos = get(obj,'position');
	yi = pos(2);
	yf = yi + pos(4);
	yc = (yi+yf)/2;
	yi_new = yc - h/2;
  pos(4) = h;
	pos(2) = yi_new;
  set(obj,'position',pos);
  
end