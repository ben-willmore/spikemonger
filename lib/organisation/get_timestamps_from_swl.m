function ts = get_timestamps_from_swl(swl)
  % ts = get_timestamps_from_swl(swl)

  % timestamps
  ts.str = {swl.timestamp}';
  
  % convert to vecotrs
  ts.vec = datevec(datenum(ts.str,'yyyymmdd-HHMMSSFFF'));
  
  % subtract the first one
  tss = ts.vec - repmat(ts.vec(1,:),size(ts.vec,1),1);
  
  % put into seconds form
  tss = datevec(datenum(tss));
  tss = tss(:,6) + 60*(tss(:,5) + 60*(tss(:,4) + 24*tss(:,2)));
  ts.absolute_s = tss;