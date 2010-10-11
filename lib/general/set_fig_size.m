function set_fig_size(w,h,id)
  % set_fig_size(w,h)
  % set_fig_size(w,h,id)
  
  if nargin==2
    id = gcf;
  end
  
  pos = get(id,'position');
  pos(3) = w;
  pos(4) = h;
  set(id,'position',pos);