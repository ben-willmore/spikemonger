function results = get_kernel_ml_fftt(grid, Y, params)


%% default parameters
% =====================

  freqs = standard_freqs;
  n.tt  = 10;
  n.ff  = size(grid,1);
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
%    X = X(~isnan(Y),:,:);
%    Y = Y(~isnan(Y));
    

    

%% initialise weights
% ======================

  w = struct;
  w.fftt = ones(size(X,2),1);

%% solve ML, via iterations
% =============================

  fprintf(' - solving ML...');

  w.fftt = safeinv(X' * X) * (Y*X)';  
  w.ff_by_tt = reshape(w.fftt(1:(end-1)),n.ff,n.tt);

  w.const = w.fftt(end);
  
  stage(1).description = 'ML';
  stage(1).w = w;
  stage(1).logE = log(0.5*( (Y-w.fftt'*X') * (Y-w.fftt'*X')' ));
  
  fprintf(' [done]\n');

%% parse results
% ================

  results = struct;
    results.w = w;
    results.stage           = stage;