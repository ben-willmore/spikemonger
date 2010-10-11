function str = timediff(t1,t2)
  dt = abs(etime(t1,t2));
  
  if dt < 60
    str = [num2str(round(dt)) 's'];
    return;
    
  elseif dt < 60*60
    m = floor(dt/60);
    s = round(dt - m*60 + 1e-12);
    str = [num2str(m) 'm' num2str(s,'%02d') 's'];
    return;
    
  else
    h = floor(dt/3600);
    m = floor((dt - h*3600)/60 + 1e-12);
    s = round(dt - h*3600 - m*60 + 1e-12);
    str = [num2str(h) 'h' num2str(m,'%02d') 'm' num2str(s,'%02d') 's'];
    
  end
end