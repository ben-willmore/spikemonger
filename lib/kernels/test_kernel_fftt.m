function results = test_kernel_fftt(results, grid, Y, params)


%% default parameters
% =====================

  freqs = standard_freqs;
  n.tt  = 10;
  n.ff  = L(freqs);
  n.fftt = n.ff * n.tt;
  stage = struct;

  time_bins_to_keep = 1:L(Y);
  
%% parse params
% =================

  if nargin==3
    
    try   time_bins_to_keep = params.time_bins_to_keep; 
      catch, end
      
    try   n.tt = params.n.tt;
      catch, end
    
  end    


  
%% get X (new)
% =========

  if islogical(time_bins_to_keep)
    n.ii = sum(time_bins_to_keep);
    tbtk = find(time_bins_to_keep);
  else
    n.ii = L(time_bins_to_keep);
    tbtk = time_bins_to_keep;
  end

  % add offset to grid
    grid_offset = n.tt-1;
    G = [zeros(n.ff,grid_offset) grid]';

  % construct X
    X = zeros(n.ii, n.ff*n.tt+1);
  
  % fill in time bins
    for ii=1:n.tt
      lag = ii-1;
      X(:, (1:n.ff) + (ii-1)*n.ff ) = G( tbtk - lag + grid_offset, : );
    end

  % add constant term
    X(:, n.ff*n.tt + 1) = 1;    
    
    
  % only requested timebins
    Y = Y(time_bins_to_keep);
    X = X(~isnan(Y),:,:);
    Y = Y(~isnan(Y));
    

  % permute
    XP.f = permute(X,[1 2 3]);
    XP.t = permute(X,[1 3 2]);   



%% compute variance
% ===================

  for ii=1:L(results.stage)
    w = results.stage(ii).w;
    Yhat = ( X*results.stage(ii).w.fftt )';

    variance.Y = var(Y);
    variance.Yhat = var(Yhat);
    variance.residual = var(Y-Yhat);
    variance.explained = variance.Y - variance.residual;
    variance.proportion_explained = variance.explained / variance.Y;
    results.stage(ii).variance = variance;
  end
