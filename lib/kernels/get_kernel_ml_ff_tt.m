function results = get_kernel_ml_ff_tt(grid, Y, params)


%% default parameters
% =====================

  time_bins_to_keep = 1:L(Y);  
  n.tt = 10;
  n.ff  = size(grid,1);
  stage = struct;

  
%% parse params
% =================

  try   time_bins_to_keep = params.time_bins_to_keep; 
    catch, end

  try   n.tt = params.n.tt;
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
%    X = X(~isnan(Y),:,:);
%    Y = Y(~isnan(Y));
    

  % permute
    XP.t = permute(X,[1 3 2]);


%% initialise weights
% ======================

  w = struct;
  w.t = ones(size(X,3),1);
  w.f = ones(size(X,2),1);

  
%% solve ML, via iterations
% =============================
  
  %fprintf('     * solving ML'); progress = 0;
  t1 = clock;
  
  for ii=1:15
    % progress
      %progress = print_progress(ii,15,progress);
      oldw = w;
    % calculate
      A.t = ( t3_v(XP.t,  w.f) );
      w.t = ( A.t' * A.t )\(A.t' * Y');
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
  
  %fprintf([' [' timediff(t1,clock) ']\n']);

%% parse results
% ================

  results = struct;
    results.w = w;
    results.stage           = stage;