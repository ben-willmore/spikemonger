function results = test_kernel_ff_tt(results, grid, Y, params)

%% default parameters
% =====================

  time_bins_to_keep = 1:L(Y);
  n.tt = 10;
  n.ff  = size(grid,1);
  
  time_dependence = false;
  return_Yhat = false;
  
  stage = struct;

  
%% parse params
% =================

  try   time_bins_to_keep = params.time_bins_to_keep; 
    catch, end

  try   n.tt = params.n.tt;
    catch, end
    
  try   time_dependence = params.time_dependence;
    catch, end
  
  try   return_Yhat = params.return_Yhat;
    catch, end
    
%% get X
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
    X = zeros(n.ii, n.ff+1, n.tt+1);
    
  % fill in time bins
    for ii=1:n.tt
      lag = ii-1;
      X(:, 1:n.ff, ii) = G( tbtk - lag + grid_offset, : );
    end

  % add constant term
    X(:,n.ff+1,n.tt+1) = 1;
    
    
  % only requested timebins
    Y = Y(time_bins_to_keep);
    %X = X(~isnan(Y),:,:);
    %Y = Y(~isnan(Y));
    


%% compute variance
% ===================

  for ii=1:L(results.stage)
    w = results.stage(ii).w;
    Yhat = ( t3_v(X,w.t)*w.f )';    

    variance.Y = var(Y);
    variance.Yhat = var(Yhat);
    variance.residual = var(Y-Yhat);
    variance.explained = variance.Y - variance.residual;
    variance.proportion_explained = variance.explained / variance.Y;
    results.stage(ii).variance = variance;
        
  end
  results.prop_ve = results.stage(end).variance.proportion_explained;
  results.prop_ves = reach(results.stage,'variance.proportion_explained');

  
%% return Yhat
% ==============

  if return_Yhat
    results.Yhat = Yhat;
  end

%% compute time dependence
% ============================

  % skip if not required
    if ~time_dependence
      return;
    end

  % to display
    fprintf('     * calculating time dependence'); 
    p = 0;

  % necessary variables
    wtt = w.t;
    A.t = nan(n.ii,n.tt+1);
    for jj=1:(n.tt+1)
        A.t(:,jj) = squeeze(X(:,:,jj))* w.f;
    end
    var_pe = nan(1,n.tt);

  % compute    
    for ii=1:n.tt
      p = print_progress(ii,n.tt,p);
      wtt(end-ii) = 0;
      Yhat        = (A.t*wtt)';
      var_resid   = var(Y-Yhat);
      var_pe(ii)  = (variance.Y - var_resid) / variance.Y;
    end
    fprintf(['[done]\n']);

  % save in structure
    results.prop_ve_vs_time = fliplr(var_pe);
