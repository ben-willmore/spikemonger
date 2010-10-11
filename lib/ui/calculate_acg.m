function [ACGs ISIs] = calculate_acg(data,maxt)
  % [ACGs ISIs] = calculate_acg(data)
  
  if nargin==1
    maxt = 30;
  end

  % spikes per sweep
  sweep_events = reach([data.set.repeats],'t','c');
  n.sweeps = L(sweep_events);
  
  % preallocate arrays
  h = Lincell(sweep_events);
  ISI_list = nan(sum(max(h-1,0)),1);
  ACG_list = nan(sum(h.*(h-1)/2),1);  
  
  % fill in ISIs and ACGs sweep by sweep
  c1=0; c2=0;
  for ss=1:n.sweeps
    spt = sort(sweep_events{ss});
    ISIt = diff(spt);
    ACGt = acg(spt);
    ISI_list(c1+(1:L(ISIt))) = ISIt;
    ACG_list(c2+(1:L(ACGt))) = ACGt;
    c1 = c1 + L(ISIt);
    c2 = c2 + L(ACGt);
  end
  
  % aggregate
  tt = 0:0.1:maxt;
  ISIs = struct;
  ISIs.tt = tt;
  ISIs.tc = midpoints(tt);
  try
    ISIs.count = histc_nolast(ISI_list,tt)';
  catch
    ISIs.count = 0*tt;
  end
  ACGs = struct;
  ACGs.tt = tt;
  ACGs.tc = midpoints(tt);
  try
    ACGs.count = histc_nolast(ACG_list,tt)';
  catch
    ACGs.count = 0*tt;
  end