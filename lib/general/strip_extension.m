function str = strip_extension(str)
  % STRIP_EXTENSION
  %   str = strip_extension(str)

  pos.dots = find(str=='.');
  if L(pos.dots)==0
    return;
  end
  
  pos.lastdot = pos.dots(end);
  if pos.lastdot==1
    error('input:error','string is just an extension!');
  end
  
  str = str(1:(pos.lastdot-1));
end