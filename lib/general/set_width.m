function set_width(obj,w)

  pos = get(obj,'position');
  pos(3) = w;
  set(obj,'position',pos);
  
end