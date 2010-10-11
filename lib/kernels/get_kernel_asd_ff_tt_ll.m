function results = get_kernel_asd_ff_tt_ll(grid, Y, params)

%% parse params
% =================

  if nargin~=3
    params = struct;
    params.time_bins_to_keep = 1:L(Y);
    
  elseif isempty(params)
    params.time_bins_to_keep = 1:L(Y);
    
  elseif ~isempty(params)

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
    X = X(~isnan(Y),:,:,:);
    Y = Y(~isnan(Y));
    
    
  % permutations
    XP.f = permute(X,[1 2 3 4]);
    XP.t = permute(X,[1.4.1.3]);
    XP.l = permute(X,[1 4 2 3]);



%% initialise weights
% ======================

  w = struct;
  w.t = ones(size(X,3),1);
  w.f = ones(size(X,2),1);
  w.l = ones(size(X,4),1);


%% solve ML, via iterations
% =============================

  fprintf(' - solving ML...');

  for ii=1:30    
    A.t = ( t4_v_v(XP.t, w.f, w.l) );
    w.t = inv(A.t' * A.t) * A.t' * Y';
    
    A.f = ( t4_v_v(XP.f, w.t, w.l) );
    w.f = inv(A.f' * A.f) * A.f' * Y';
    
    A.l = ( t4_v_v(XP.l, w.f, w.t) );
    w.l = inv(A.l' * A.l) * A.l' * Y';    
  end
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(1).description = 'ML';
  stage(1).w = w;
  stage(1).logE = log(0.5*( (Y-w.l'*A.l') * (Y-w.l'*A.l')' ));
  
  fprintf(' [done]\n');



%% run ASD
% =========

  rho.t = 0;
  rho.f = 0;
  rho.l = 0;
  d.t = 1;
  d.f = 1;
  d.l = 1;
  asdcov = struct;

  fprintf(' - solving ASD');

  for ii=1:3
    
    fprintf('.');

    A.t = ( t4_v_v(XP.t, w.f, w.l) );
    asdcov(ii).t = get_asd_covariance_matrix(A.t',Y,w.t,rho.t,d.t);
      C.t = asdcov(ii).t.C;
      D.t = asdcov(ii).t.invC;
      rho.t = asdcov(ii).t.rho;
      d.t = asdcov(ii).t.di;
    w.t = inv( A.t'*A.t + D.t ) * A.t' * Y';
    
    A.f = ( t4_v_v(XP.f, w.t, w.l) );
    asdcov(ii).f = get_asd_covariance_matrix(A.f',Y,w.f,rho.f,d.f);
      C.f = asdcov(ii).f.C;
      D.f = asdcov(ii).f.invC;
      rho.f = asdcov(ii).f.rho;
      d.f = asdcov(ii).f.di;
    w.f = inv( A.f'*A.f + D.f ) * A.f' * Y';
    
    A.l = ( t4_v_v(XP.l, w.f, w.t) );
    asdcov(ii).l = get_asd_covariance_matrix(A.l',Y,w.l,rho.l,d.l);
      C.l = asdcov(ii).l.C;
      D.l = asdcov(ii).l.invC;
      rho.l = asdcov(ii).l.rho;
      d.l = asdcov(ii).l.di;
    w.l = inv( A.l'*A.l + D.l ) * A.l' * Y';
    
  end
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(2).description = 'ASD';
  stage(2).w = w;
  stage(2).logE = log(0.5*( (Y-w.l'*A.l') * (Y-w.l'*A.l')' ));
  stage(2).params.C = C;
  stage(2).params.invC = D;
  stage(2).params.rho = rho;
  stage(2).params.d = d;

  fprintf(' [done]\n');
  

%% regularised ML, given cov matrices
% ====================================

  fprintf(' - solving ASD-regularised ML...');

  for ii=1:30
    A.t = ( t4_v_v(XP.t, w.f, w.l) );
    w.t = inv( A.t' * A.t + D.t ) * A.t' * Y';
    A.f = ( t4_v_v(XP.f, w.t, w.l) );
    w.f = inv( A.f' * A.f + D.f ) * A.f' * Y';
    A.l = ( t4_v_v(XP.l, w.f, w.t) );    
    w.l = inv( A.l'*A.l + D.l ) * A.l' * Y';
  end

  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(3).description = 'ASD-regularised ML';
  stage(3).w = w;
  stage(3).logE = log(0.5*( (Y-w.l'*A.l') * (Y-w.l'*A.l')' ));
  
  fprintf(' [done]\n');
  
  
  
%% parse results
% ================

  results = struct;
    results.w = w;
    results.covariance.C    = C;
    results.covariance.invC = D;
    results.stage           = stage;