function set_height(obj,w)

  pos = get(obj,'position');
  pos(4) = h;
  set(obj,'position',pos);
  
end