function results = test_kernel_asd_ff_tt(results, grid, Y, params)

%% parse params
% =================

  if nargin~=4
    params = struct;
  end
  
  if isempty(params)
    params.time_bins_to_keep = 1:L(Y);
    params.n.tt = 10;
    
  elseif ~isempty(params)

  end    
  
%% initialise
% =============

  freqs = standard_freqs;
  n.ff  = L(freqs);
  n.tt  = params.n.tt;
  stage = struct;
  

%% get X
% =============
  X = grid';

  XL = zeros( size(X,1), n.ff, n.tt );
    for ii = 1:n.tt
      lag = ii-1;
      XL( ii:end, :, ii) = X( 1:(end-lag), :);
    end
  X = XL;

  % add constant term
    X(:,n.ff+1,n.tt+1) = 1;

  % only requested timebins
    Y = Y(params.time_bins_to_keep);
    X = X(params.time_bins_to_keep, :, :);    
    
  % permute
    XP.f = permute(X,[1 2 3]);
    XP.t = permute(X,[1 3 2]);


%% compute variance
% ===================

  for ii=1:L(results.stage)
    w = results.stage(ii).w;
    Yhat = ( t3_v(XP.f,w.t)*w.f )';

    variance.Y = var(Y);
    variance.Yhat = var(Yhat);
    variance.residual = var(Y-Yhat);
    variance.explained = variance.Y - variance.residual;
    variance.proportion_explained = variance.explained / variance.Y;
    results.stage(ii).variance = variance;
  end
