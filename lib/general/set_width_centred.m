function set_width_centred(obj,w)

  pos = get(obj,'position');
	xi = pos(1);
	xf = xi + pos(3);
	xc = (xi+xf)/2;
	xi_new = xc - w/2;
  pos(3) = w;
	pos(1) = xi_new;
  set(obj,'position',pos);
  
end