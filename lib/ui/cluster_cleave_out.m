function C = cluster_cleave_out(C,id,ti,tf,dirs)
  % C = cluster_cleave_out(C,id,ti,tf)
  %
  % helper for cluster_ui
  
  % retrieve cluster data
  psth = C.psth(id);
  acgs = C.acgs(id);
  isis = C.isis(id);
  sve = C.sve(id);
  data = C.data(id);
  sweep_count = C.sweep_count{id};
  
  % get sweep list
  swl = get_event_file(dirs,'sweep_list');
  ts = get_timestamps_from_swl(swl);
  
  
  %% cleave
  % =========
  
  % fix data
  for ss=1:L(data.set)
    
    % which repeats to keep, based on timestamp order
    n.repeats = L(data.set(ss).repeats); 
    keep_repeat = nan(1,n.repeats);
    for rr = 1:n.repeats
      sweep_id = find(ismember(ts.str,data.set(ss).repeats(rr).timestamp));
      keep_repeat(rr) = (sweep_id < ti) || (sweep_id > tf);      
    end
    data.set(ss).repeats = data.set(ss).repeats(keep_repeat==1);
    
    % fix repeat ids
    n.repeats = L(data.set(ss).repeats);
    for rr=1:n.repeats
      data.set(ss).repeats(rr).repeat_id = 0*data.set(ss).repeats(rr).t + rr;
    end
    
    if sum(keep_repeat)>0
      data.set(ss).spikes.t = [data.set(ss).repeats.t];
      data.set(ss).spikes.repeat_id = [data.set(ss).repeats.repeat_id];
    else
      data.set(ss).spikes.t = [];
      data.set(ss).spikes.repeat_id = [];
    end    

  end      
  
  % fix psth
  psth = struct;
  dhs = [2 5 10 25];
  maxt = ceil(max([data.set.length_signal_ms]));
  spike_times = reach(data.set,'spikes.t');
  for dd=1:L(dhs)
    dh = dhs(dd);
    fn_psth = ['count_' n2s(dh) 'ms_bins'];
    fn_tt = ['tt_' n2s(dh) 'ms_bins'];
    tt = 0:dh:maxt;
    psth.(fn_psth) = histc_nolast(spike_times,tt);
    psth.(fn_tt)   = midpoints(tt);
  end
  
  % fix acgs
  [acgs isis] = calculate_acg(data);
  
  % fix sve
  sve = sahani_variance_explainable_2(data);
  
  % fix sweep_count
  sweep_count(ti:tf) = nan;  
  
  
  %% save into C
  % ===============
  
  C.psth(id) = psth;
  C.acgs(id) = acgs;
  C.isis(id) = isis;
  C.sve(id) = sve;
  C.data(id) = data;
  C.sweep_count{id} = sweep_count;