function data = change_stdmax(data,stdmax)
  % data = change_stdmax(data,stdmax)
  %
  % Reclusters, without changing the features or n_clusters; just changes
  % the maximum std.dev allowed from a cluster centre.
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
  
%% if stdmax is the same as before, then quit asap
% =================================================

stdmax      = stdmax(:)';
n.clusters  = L(data.cluster)-1;

if isequal(stdmax, data.EM.stdmax)
  return;
end

switch L(stdmax)
  case 1
    if isequal( repmat(stdmax, 1, n.clusters), data.EM.stdmax)
      return;
    end
  case n.clusters
    if isequal( repmat(data.EM.stdmax, 1, n.clusters), stdmax)
      return;
    end
  otherwise
    error('input:error','the length of stdmax can only be 1, or the number of clusters');
end
  
%% recalculate C
% ===============

  [junk C] = max(data.EM.P,[],2);
  switch L(stdmax)
    case 1
      C(data.EM.best_NStds > stdmax) = n.clusters+1;
    otherwise
      for cc=1:n.clusters
        C( (C==cc)&(data.EM.best_NStds > stdmax(cc)) ) = n.clusters+1;
      end
  end
  C = C';
  
%% subdivide data into clusters
% ================================

  fields    = fieldnames(data.spikes);
  n.fields  = L(fields);
  
  for ii=1:(n.clusters+1)
    for jj=1:n.fields
      field = pick(fields,jj,'c');
      cluster(ii).spikes.(field) = data.spikes.(field)(:,C==ii);
    end
    %cluster(ii).sweeps  = spikes_to_sweeps(cluster(ii).spikes);
    cluster(ii).nspikes = L(cluster(ii).spikes.t_absolute_dt);
  end
  
%% calculate some statistics
% ===========================

% psth
  for cc=1:(n.clusters+1)
    %tt = 0 : 5 : (floor(data.metadata.maxt_ms*5)/5);
    %cluster(cc).psth.tt     = tt(1:(end-1))+2.5;
    tt = linspace(0, data.metadata.maxt_ms, 100);
    cluster(cc).psth.tt     = tt(1:(end-1)) + (tt(2)-tt(1))/2;
    cluster(cc).psth.count  = histc(cluster(cc).spikes.t_insweep_ms,tt);
    cluster(cc).psth.count  = cluster(cc).psth.count(1:(end-1));
  end
  
% autocorrelogram & ISI
  for cc=1:(n.clusters+1)
    if cluster(cc).nspikes == 0
      cluster(cc).autocorrelogram.tt          = [];
      cluster(cc).autocorrelogram.count       = [];
      cluster(cc).interspike_interval.tt      = [];
      cluster(cc).interspike_interval.count   = [];
    else
      [tt acg isi] = get_autocorrelogram(cluster(cc).spikes,0.5);
      cluster(cc).autocorrelogram.tt    = tt;
      cluster(cc).autocorrelogram.count = acg;
      cluster(cc).interspike_interval.tt    = tt;
      cluster(cc).interspike_interval.count = isi;
    end
  end
  
% spike counts over repeat number
  n.repeats = data.metadata.n.repeats;  
  for cc = 1:(n.clusters+1)
    repeatcounts = nan * zeros( 1, n.repeats );
      for ii = 1:n.repeats
        repeatcounts(ii) = sum(cluster(cc).spikes.repeat_id == ii);
      end
    cluster(cc).spikes_per_repeat.repeat_id  = 1:n.repeats;
    cluster(cc).spikes_per_repeat.count      = repeatcounts;
  end  

  
%% prepare output structure
% ===========================

data.cluster = cluster;
data.nspikes = [data.cluster.nspikes];

  data.EM.C = C;
  data.EM.stdmax = stdmax;
  
  
end



