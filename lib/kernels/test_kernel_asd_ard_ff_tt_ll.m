function results = test_kernel_asd_ard_ff_tt_ll(results, grid, Y, params)

%% parse params
% =================

  if nargin~=4
    params = struct;
  end
      
  if ~isfield(params,'time_bins_to_keep')
    params.time_bins_to_keep = 1:L(Y);
  end
  
  if ~isfield(params,'return_Yhat')
    params.return_Yhat = 0;
  end
  
  
%% initialise
% =============

  freqs = standard_freqs;
  n.ff  = L(freqs);
  n.tt  = 10;
  stage = struct;
  
  levels = unique(grid(:));
  levels = levels(levels~=0);
  n.ll = L(levels);


%% get X
% =============

  % start with grid
    X = grid';

  % add lag
    XL = zeros( size(X,1), n.ff, n.tt );
      for ii = 1:n.tt
        lag = ii-1;
        XL( ii:end, :, ii) = X( 1:(end-lag), :);
      end
    X = XL;
    clear XL;
    
  % add levels
    XL = false( size(X,1), size(X,2), size(X,3), n.ll );
      for ii = 1:n.ll
        XL(:,:,:,ii) = (X==levels(ii));
      end
    X = XL;
    clear XL;
    
  % add constant term
    X(:,n.ff+1,n.tt+1,n.ll+1) = 1;

  % only keep requested timebins
    Y = Y(params.time_bins_to_keep);
    X = X(params.time_bins_to_keep, :, :, :);    
    
  % permutations
    XP.f = permute(X,[1 2 3 4]);
    XP.t = permute(X,[1.4.1.3]);
    XP.l = permute(X,[1 4 2 3]);


%% compute variance
% ===================

  for ii=1:L(results.stage)
    w = results.stage(ii).w;
    Yhat = ( t4_v_v(XP.f, w.t, w.l)*w.f )';

    variance.Y = var(Y);
    variance.Yhat = var(Yhat);
    variance.residual = var(Y-Yhat);
    variance.explained = variance.Y - variance.residual;
    variance.proportion_explained = variance.explained / variance.Y;
    results.stage(ii).variance = variance;
    
    if params.return_Yhat
      results.stage(ii).Yhat = Yhat;
    end
    
  end
