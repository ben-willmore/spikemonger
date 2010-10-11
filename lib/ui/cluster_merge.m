function C = cluster_merge(C,ids)
  % C = cluster_merge(C,ids)
  %
  % helper for cluster_ui.m

  if L(ids)==1
    return;
  end
  
  MAX_N_SHAPES = 10;
  MAX_N_FSP = 200;

  
  %% recalculate
  % ==============
  
  n.ids = L(ids);
  n.spikes = pick(cellfun(@sum, C.sweep_count),ids);
  
  % eg feature space
  fsp = C.fsp{ids(1)};
  for ii=2:n.ids
    fsp = [fsp; C.fsp{ids(ii)}];
  end
  tokeep = head(randperm(size(fsp,1)),MAX_N_FSP);
  fsp = fsp(tokeep,:,:);
    
  % eg shapes
  sh = C.sh{ids(1)};
  for ii=2:n.ids
    sh = [sh; C.sh{ids(ii)}];
  end
  tokeep = head(randperm(size(sh,1)),MAX_N_SHAPES);
  sh = sh(tokeep,:,:);
  
  % shapes_mean
  sh_mean = C.sh_mean{ids(1)} * n.spikes(1);
  for ii=2:n.ids
    sh_mean = sh_mean + C.sh_mean{ids(ii)} * n.spikes(ii);
  end
  sh_mean = sh_mean / sum(n.spikes);
  
  % psth
  psth = C.psth(ids(1));
  for ii=2:n.ids
    psth.count_2ms_bins = psth.count_2ms_bins + C.psth(ids(ii)).count_2ms_bins;
    psth.count_5ms_bins = psth.count_5ms_bins + C.psth(ids(ii)).count_5ms_bins;
    psth.count_10ms_bins = psth.count_10ms_bins + C.psth(ids(ii)).count_10ms_bins;
    psth.count_25ms_bins = psth.count_25ms_bins + C.psth(ids(ii)).count_25ms_bins;
  end
  
  % data
  data = C.data(ids(1));
  n.sets = L(data.set);
  for ii=2:n.ids
    for ss=1:n.sets
      data.set(ss).spikes.t = [data.set(ss).spikes.t C.data(ids(ii)).set(ss).spikes.t];
      data.set(ss).spikes.repeat_id = [data.set(ss).spikes.repeat_id C.data(ids(ii)).set(ss).spikes.repeat_id];
      for rr=1:L(data.set(ss).repeats)
        try
          data.set(ss).repeats(rr).t = [data.set(ss).repeats(rr).t C.data(ids(ii)).set(ss).repeats(rr).t];
          data.set(ss).repeats(rr).repeat_id = [data.set(ss).repeats(rr).repeat_id C.data(ids(ii)).set(ss).repeats(rr).repeat_id];
        catch
          error('merge:error',['you tried to merge two clusters that' ...
		    ' were not defined over the same range. this' ...
		     ' might be fixed in a later spikemonger, but' ...
		      ' for now, only merge uncleaved clusters']);
        end
      end
    end
  end
  
  % sve
  sve = sahani_variance_explainable_2(data);

  % acgs
  [acgs isis] = calculate_acg(data);

  % sweep count
  sweep_count = C.sweep_count{ids(1)};
  for ii=2:n.ids
    sweep_count = sweep_count + C.sweep_count{ids(ii)};
  end
  
  % shape correlation
  shape_correlation = C.shape_correlation(ids(1)) * n.spikes(1);  
  for ii=2:n.ids
    shape_correlation = shape_correlation + C.shape_correlation(ids(ii)) * n.spikes(ii);
  end
  shape_correlation = shape_correlation / sum(n.spikes);
  
  %% update C
  % ===============
  
  % replace ids(1) with new values
  C.fsp{ids(1)} = fsp;
  C.sh{ids(1)}  = sh;
  C.sh_mean{ids(1)} = sh_mean;
  C.psth(ids(1)) = psth;
  C.acgs(ids(1)) = acgs;
  C.isis(ids(1)) = isis;
  C.sve(ids(1)) = sve;
  C.data(ids(1)) = data;
  C.sweep_count{ids(1)} = sweep_count;
  C.shape_correlation(ids(1)) = shape_correlation;
  
  % delete others
  C = cluster_delete(C,ids(2:end));
  