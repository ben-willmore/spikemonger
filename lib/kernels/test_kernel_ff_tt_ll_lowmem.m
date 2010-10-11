function results = test_kernel_ff_tt_ll_lowmem(results, grid, Y, params)


%% default parameters
% =====================

  freqs = standard_freqs;
  n.ff  = L(freqs);
  n.tt  = 10;
  stage = struct;
  
  levels = unique(grid(:));
  levels = levels(levels~=0);
  n.ll = L(levels);

  time_bins_to_keep = 1:L(Y);
  
  return_Yhat = 0;
  
%% parse params
% =================

  try   time_bins_to_keep = params.time_bins_to_keep; 
    catch, end

  try   n.tt = params.n.tt;
    catch, end

  try   return_Yhat = params.return_Yhat;
    catch, end
    
%% parse params
% =================

  if nargin~=3
    params = struct;
    params.time_bins_to_keep = 1:L(Y);
    
  elseif isempty(params)
    params.time_bins_to_keep = 1:L(Y);
    
  elseif ~isempty(params)

  end    



%% get X (new)
% =============

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

  % construct XL
    XL = zeros(n.ii, n.ff+1, n.tt+1);    
  
  % fill in time bins
    for ii=1:n.tt
      lag = ii-1;
      XL(:, 1:n.ff, ii) = G( tbtk - lag + grid_offset, : );
    end

  % add levels
    X = false( n.ii, n.ff+1, n.tt+1, n.ll+1 );
      for ii = 1:n.ll
        X(:,:,:,ii) = (XL==levels(ii));
      end
      
  % add constant term
    X(:,end,end,end) = true;
    clear XL G;
      

  % only keep requested timebins
    Y = Y(time_bins_to_keep);
    X = X(~isnan(Y),:,:,:);
    Y = Y(~isnan(Y));
    

%% compute variance
% ===================

  for ii=1:L(results.stage)
    w = results.stage(ii).w;
    
    A.t = nan(n.ii,n.tt+1);
        for jj=1:(n.tt+1)
          A.t(:,jj) = t3_v_v( squeeze(X(:,:,jj,:)), w.f, w.l);
        end
        
    Yhat = ( A.t*w.t )';

    variance.Y = var(Y);
    variance.Yhat = var(Yhat);
    variance.residual = var(Y-Yhat);
    variance.explained = variance.Y - variance.residual;
    variance.proportion_explained = variance.explained / variance.Y;
    results.stage(ii).variance = variance;
    
    if return_Yhat
      results.stage(ii).Yhat = Yhat;
    end
    
  end
