function results = get_kernel_asd_ard_ff_tt(grid, Y, params)

%% default parameters
% =====================

  time_bins_to_keep = 1:L(Y);  
  n.tt = 10;
  n.ff  = size(grid,1);
  stage = struct;
  show_progress = 1;
  
%% parse params
% =================

  try   time_bins_to_keep = params.time_bins_to_keep; 
    catch, end

  try   n.tt = params.n.tt;
    catch, end

  try   show_progress = params.show_progress;
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

  % permute
    XP.t = permute(X,[1 3 2]);


%% initialise weights
% ======================

  w = struct;
  w.t = ones(size(X,3),1);
  w.f = ones(size(X,2),1);
  

%% solve ML, via iterations
% =============================
  
  if show_progress
    fprintf('     * solving ML'); 
    progress = 0;
    t1 = clock;
  end
  
  for ii=1:15
    % progress
      if show_progress,
        progress = print_progress(ii,15,progress);
      end
      oldw = w;
    % calculate
      A.t = ( t3_v(XP.t,  w.f) );
      w.t = ( A.t' * A.t)\(A.t' * Y');
      A.f = ( t3_v(X,w.t) );
      w.f = ( A.f' * A.f )\(A.f' * Y');
    % check that the improvement is reasonable
      %diffw = sqrt( sum((w.t - oldw.t).^2) + sum((w.f - oldw.f).^2) );
      diffw = sqrt( ...
        sum( ((w.t - oldw.t) ./ oldw.t).^2) + ...
        sum( ((w.f - oldw.f) ./ oldw.f).^2) );
      if diffw<1e-8
        break;
      end        
  end
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  w.const    = w.f(end) * w.t(end);
  
  stage(1).description = 'ML';
  stage(1).w = w;
  stage(1).logE = log(0.5*( (Y-w.f'*A.f') * (Y-w.f'*A.f')' ));
  
  if show_progress
    fprintf([' [' timediff(t1,clock) ']\n']);
  end
  
  
%% run ASD
% =========


  rho.t = 0;
  rho.f = 0;
  d.t = 1;
  d.f = 1;
  asdcov = struct;

  if show_progress
    fprintf('     * solving ASD');
    t1 = clock;
  end

  for ii=1:3
    
    if show_progress
      fprintf('.');
    end
    
    A.t = t3_v(XP.t, w.f);
    asdcov(ii).t = get_asd_covariance_matrix(A.t',Y,w.t,rho.t,d.t);
      C.t = asdcov(ii).t.C;
      D.t = asdcov(ii).t.invC;
      rho.t = asdcov(ii).t.rho;
      d.t = asdcov(ii).t.di;
    w.t = ( A.t'*A.t + D.t ) \ (A.t' * Y');

    A.f = t3_v(X, w.t);

    asdcov(ii).f = get_asd_covariance_matrix(A.f',Y,w.f,rho.f,d.f);
      C.f = asdcov(ii).f.C;
      D.f = asdcov(ii).f.invC;
      rho.f = asdcov(ii).f.rho;
      d.f = asdcov(ii).f.di;
    w.f = ( A.f'*A.f + D.f ) \ (A.f' * Y');

  end
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(2).description = 'ASD';
  stage(2).w = w;
  stage(2).logE = log(0.5*( (Y-w.f'*A.f') * (Y-w.f'*A.f')' ));
  stage(2).params.C = C;
  stage(2).params.invC = D;
  stage(2).params.rho = rho;
  stage(2).params.d = d;

  if show_progress
    fprintf([' [' timediff(t1,clock) ']\n']);
  end
  

%% ASD-regularised ML, given cov matrices
% ====================================

  if show_progress
    fprintf('     * solving ASD-regularised ML...');
    t1 = clock;
  end

  for ii=1:10          
    A.t = ( t3_v(XP.t,w.f) );
    w.t = ( A.t' * A.t + D.t ) \ (A.t' * Y');
    A.f = ( t3_v(X,w.t) );
    w.f = ( A.f' * A.f + D.f ) \ (A.f' * Y');
  end

  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(3).description = 'ASD-regularised ML';
  stage(3).w = w;
  stage(3).logE = log(0.5*( (Y-w.f'*A.f') * (Y-w.f'*A.f')' ));
  
  if show_progress
    fprintf([' [' timediff(t1,clock) ']\n']);
  end
  

%% run ARD in ASD basis
% ========================

  if show_progress
    fprintf('     * solving ASD-regularised ARD');
    t1 = clock;
  end
  
  alpha.t = ones(n.tt+1,1);
  alpha.f = ones(n.ff+1,1);
  
  [EV.t ED.t] = eig(C.t);
  [EV.f ED.f] = eig(C.f);
  
  R.t = EV.t * sqrt(ED.t);
  R.f = EV.f * sqrt(ED.f);
  
  for ii=1:3
    if show_progress
      fprintf('.');
    end
    A.t  = t3_v(XP.t, w.f);
    A2.t = A.t * R.t';
    ardasdcov(ii).t = get_ard_covariance_matrix( A2.t', Y, inv(R.t)'*w.t, alpha.t);
    C.t = ardasdcov(ii).t.C;
    D.t = ardasdcov(ii).t.invC;
    w.t = R.t' * (( A2.t'*A2.t + D.t ) \ (A2.t' * Y'));

    A.f  = t3_v(X, w.t);
    A2.f = A.f * R.f';
    ardasdcov(ii).f = get_ard_covariance_matrix( A2.f', Y, inv(R.f)'*w.f, alpha.f);
    C.f = ardasdcov(ii).f.C;
    D.f = ardasdcov(ii).f.invC;
    w.f = R.f' * (( A2.f'*A2.f + D.f ) \ (A2.f' * Y'));

  end  
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(4).description = 'ASD-regularised ARD';
  stage(4).w = w;
  stage(4).logE = log(0.5*( (Y-w.f'*A.f') * (Y-w.f'*A.f')' ));
  stage(4).params.C = C;
  stage(4).params.invC = D;
  stage(4).params.alpha.t = diag(C.t);
  stage(4).params.alpha.f = diag(C.f); 
  
  if show_progress
    fprintf([' [' timediff(t1,clock) ']\n']);
  end
    
  
%% regularised ML, given cov matrices
% ====================================

  if show_progress
    fprintf('     * solving ASD-ARD-regularised ML...');
    t1 = clock;
  end

  for ii=1:10
    A.t  = ( t3_v(XP.t,w.f) );
    A2.t = A.t * R.t';    
    w.t  = R.t' * (( A2.t'*A2.t + D.t ) \ (A2.t' * Y'));
    
    A.f  = ( t3_v(X,w.t) );
    A2.f = A.f * R.f';
    w.f  = R.f' * (( A2.f'*A2.f + D.f ) \ (A2.f' * Y'));
  end

  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(5).description = 'ASD-ARD-regularised ML';
  stage(5).w = w;
  stage(5).logE = log(0.5*( (Y-w.f'*A.f') * (Y-w.f'*A.f')' ));
  stage(5).params = stage(4).params;
  
  if show_progress
    fprintf([' [' timediff(t1,clock) ']\n']);
  end
  
%% parse results
% ================

  results = struct;
    results.w = w;
    results.covariance.C    = C;
    results.covariance.invC = D;
    results.stage           = stage;