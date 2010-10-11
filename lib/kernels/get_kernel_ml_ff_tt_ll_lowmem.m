function results = get_kernel_ml_ff_tt_ll_lowmem(grid, Y, params)


%% default parameters
% =====================

  time_bins_to_keep = 1:L(Y);  
  n.tt = 10;
  n.ff  = size(grid,1);
  stage = struct;

  levels = unique(grid(:));
  levels = levels(levels~=0);
  n.ll = L(levels);

  
%% parse params
% =================

  try   time_bins_to_keep = params.time_bins_to_keep; 
    catch, end

  try   n.tt = params.n.tt;
    catch, end


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
    %X = X(~isnan(Y),:,:,:);
    %Y = Y(~isnan(Y));
    


%% initialise weights
% ======================

  w = struct;
  w.t = ones(n.tt+1, 1);
  w.f = ones(n.ff+1, 1);
  w.l = ones(n.ll+1 ,1);


%% solve ML, via iterations
% =============================

  fprintf('     * solving ML (slowly)'); progress = 0;
  t1 = clock;
  
  for ii=1:30    
    % progress
      progress = print_progress(ii,30,progress);
      oldw = w;
      
    % calculate
      A.t = nan(n.ii,n.tt+1);
        for jj=1:(n.tt+1)
          A.t(:,jj) = t3_v_v( squeeze(X(:,:,jj,:)), w.f, w.l);
        end
      w.t = (A.t' * A.t)\(A.t' * Y');
      
      A.f = nan(n.ii,n.ff+1);
        for jj=1:(n.ff+1)
          A.f(:,jj) = t3_v_v( squeeze(X(:,jj,:,:)), w.t, w.l);
        end
      w.f = (A.f' * A.f)\(A.f' * Y');
      
      A.l = nan(n.ii,n.ll+1);
        for jj=1:(n.ll+1)
          A.l(:,jj) = t3_v_v( squeeze(X(:,:,:,jj)), w.f, w.t);
        end
      w.l = (A.l' * A.l)\(A.l' * Y');

    % check that the improvement is reasonable
      try 
        diffw = sqrt( ...
          sum( ((w.t - oldw.t) ./ oldw.t).^2) + ...
          sum( ((w.f - oldw.f) ./ oldw.f).^2) + ...
          sum( ((w.l - oldw.l) ./ oldw.l).^2));
      catch
        keyboard;
      end
      
      if diffw<1e-8
        break;
      end        
    
  end
  
  w.ff_by_tt = w.f(1:(end-1)) * w.t(1:(end-1))';
  
  stage(1).description = 'ML';
  stage(1).w = w;
  stage(1).logE = log(0.5*( (Y-w.l'*A.l') * (Y-w.l'*A.l')' ));
  
  fprintf([' [' timediff(t1,clock) ']\n']);

  
%% parse results
% ================

  results = struct;
    results.w = w;
    results.stage           = stage;