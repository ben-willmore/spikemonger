function clusters = EM_cut(CEs, n_clusters, stdmax)
  % data = EM_cut(CEs, n_clusters, stdmax)
  %
  % Runs EM on the data, using the feature space (fsp) provided, as well as the
  % number of clusters and maximum std.dev (away from a cluster centre)
  % allowed.
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 26-May-2010
  %   - distributed under GPL v3 (see COPYING)
  


%% initialise
% =============

%warning off MATLAB:singularMatrix
%warning off MATLAB:nearlySingularMatrix

%{
% get features
  [features shapes_aligned] = extract_features(data);
  data.spikes.shapes_aligned = shapes_aligned;
  
  switch nargin
    case 1
      features_to_use = fieldnames(features);
      n.clusters = 1;
      stdmax = 3;
    case 2
      n.clusters = 1;
      stdmax = 3;
    case 3
      n.clusters = n_clusters;
      stdmax = 3;
    case 4
      n.clusters = n_clusters;
  end
  
% parse features
  X = [];
  for ii=1:L(features_to_use)
    X = [X; features.(features_to_use{ii})];
  end
  X = X';
%}

%% kmeans for EM start point
% ===========================

%   [kC kM ksumD] = kmeans(X, n.clusters);
%   kM = kM'; 
%   kV = nan*zeros( size(kM,1), size(kM,1), n.clusters);
%   kW = nan*zeros(1, n.clusters);
%    for ii=1:n.clusters
%      kV(:,:,ii) = diag(sum(X(kC==ii,:).^2) / sum(kC==ii));
%      kW(ii)     = sum(kC==ii) / size(X,1);
%    end
%   init.M = kM;
%   init.V = kV;
%   init.W = kW;
  
%% EM
% ====

%try
%  [W M V]       = EM_GM_compiled( CEs.fsp, n_clusters );
%catch

%X = CEs.fsp ./ repmat(std(CEs.fsp),size(CEs.fsp,1),1);
X = 1000*CEs.fsp; % normalise_over_bigger_dim(CEs.fsp);
%tic;
[W M V]       = EM_GM_compiled( X, n_clusters );
%toc
tic;
%[W2 M2 V2 junk]  = EM_GM( X, n_clusters );
%[W M V junk]  = EM_GM( X, n_clusters );
toc
%end

%% fix covariances if necessary
for ii=1:n_clusters
  for jj=1:size(X,2)
    if V(jj,jj,ii) == 0
      V(jj,jj,ii) = eps;
    end
  end
end

% order clusters by descending weights
[W sortperm] = sort(W,'descend');
M = M(:,sortperm);
V = V(:,:,sortperm);

[C P best_P NStds best_NStds]  = EM_classify(X, W, M, V );
C(best_NStds>stdmax) = n_clusters + 1;
C = C';
loglik = sum(log(sum(P,2)));

  
%% subdivide candidate events into clusters
% =============================================

fields = setdiff(fieldnames(CEs),'fsp');
clusters = struct;

  data.EM.W = W;
  data.EM.M = M;
  data.EM.V = V;
  data.EM.C = C;
  
clusters.W = W;
clusters.M = M;
clusters.V = V;
clusters.C = C';
clusters.P = P;
clusters.best_P = best_P;
clusters.NStds = NStds;
clusters.best_NStds = best_NStds;
clusters.loglik = loglik;

n_spikes = nan(1,n_clusters+1);
for ii=1:(n_clusters+1)
  n_spikes(ii) = sum(C==ii);
end
clusters.n_spikes = n_spikes
1
%%
%{
%% subdivide data into clusters
% ================================

  fields    = fieldnames(data.spikes);
  n.fields  = L(fields);
  
  for ii=1:(n_clusters+1)
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
  %tt = 0:5:1000;
  for cc=1:(n_clusters+1)
      %tt = 0 : 5 : (floor(data.metadata.maxt_ms*5)/5);
      %cluster(cc).psth.tt     = tt(1:(end-1))+2.5;
      tt = linspace(0, data.metadata.maxt_ms, 100);
      cluster(cc).psth.tt     = tt(1:(end-1)) + (tt(2)-tt(1))/2;
      cluster(cc).psth.count  = histc(cluster(cc).spikes.t_insweep_ms,tt);
      cluster(cc).psth.count  = cluster(cc).psth.count(1:(end-1));
  end
  
% autocorrelogram & ISI
  for cc=1:(n_clusters+1)
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
  for cc = 1:(n_clusters+1)
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

data.EM = struct;
  data.EM.features = features_to_use;
  data.EM.X = X;
  data.EM.W = W;
  data.EM.M = M;
  data.EM.V = V;
  data.EM.C = C;
  data.EM.P = P;
  data.EM.best_P = best_P;
  data.EM.NStds = NStds;
  data.EM.best_NStds = best_NStds;
  data.EM.stdmax = stdmax;
  data.EM.log_likelihood = loglik;
  
  
end



%}