function sve = sahani_variance_explainable_2(data,offset)

  if nargin==1
    offset = 0;
  end

  % parameters
  dhs = [2 5 10 25];
  maxt = max([data.set.length_signal_ms]);
  
  % prepare for pooled
  dp = struct;
  dp.repeats = [data.set.repeats];
  dp.stim_params = nan;  

  % calculate
  sve = struct;
  sve.pooled = struct;
  for dh=dhs
    tt = (dh*offset):dh:maxt;
    fn = ['at_' n2s(dh) 'ms'];
    try
      sve.(fn) = sahani_variance_explainable(data.set, tt);
    catch, end
    try
      sve.pooled.(fn) = sahani_variance_explainable(dp,tt);
    catch, end
  end
  
  % organise
  for dh=dhs
    fn = ['at_' n2s(dh) 'ms'];
    sve.percentage_signal.(fn)  = sve.(fn).percentage_signal;
    sve.percentage_noise.(fn)   = sve.(fn).percentage_noise;
    sve.noise_ratio.(fn)        = sve.(fn).noise_ratio;
    sve.pooled.percentage_signal.(fn)  = sve.pooled.(fn).percentage_signal;
    sve.pooled.percentage_noise.(fn)   = sve.pooled.(fn).percentage_noise;
    sve.pooled.noise_ratio.(fn)        = sve.pooled.(fn).noise_ratio;
  end