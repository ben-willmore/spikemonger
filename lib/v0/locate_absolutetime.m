function [sweepid relative_time] = locate_absolutetime(t, maxt)
  % [sweepid relative_time] = locate_absolutetime(t, maxt)
  
  sweepid = 1 + floor((t-1) / maxt);
  relative_time = mod(t, maxt);
    
  if relative_time == 0
    relative_time = maxt;
  end
  
end