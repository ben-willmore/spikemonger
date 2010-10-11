function v = sahani_variance_explained(sweeps,metadata,dt,excisions)

  t = {sweeps.spike_t_insweep_ms};
  maxt = metadata.maxt_ms;

  % remove excisions (if included in input variables)
    if nargin==4
      sweeps_to_remove = excisions.boundaries.sweeps(excisions.durations.ms > 10);
      sweeps = sweeps(setdiff(1:L(sweeps),sweeps_to_remove));
    end
  
  % accumulate histograms  
    hists = cell(metadata.n.sets,1);
    for ii=1:metadata.n.sets
      ts = find([sweeps.set_id]==ii);
      hists{ii} = zeros(L(ts),L(0:dt:maxt));
      for jj=1:L(ts)
        if ~isempty(t{ts(jj)})
          hists{ii}(jj,:) = histc(t{ts(jj)},0:dt:maxt);
        end
      end
      hists{ii} = hists{ii}(:,1:(end-1));
    end
  
  % calculate variance explained
    vm = zeros(metadata.n.sets,1);
    ve = zeros(metadata.n.sets,1);

    for ii=1:metadata.n.sets
      h = hists{ii};
      N = size(h,1);
      vm(ii) = var(mean(h));
      ve(ii) = 1/(N-1) * (N * var(mean(h)) - mean(var(h,[],2)));
    end

    v.m = sum(vm);
    v.e = sum(ve);
    v.u = v.m-v.e;
    v.noise = v.u/v.e;
    if v.noise<0, v.noise = Inf; end

end