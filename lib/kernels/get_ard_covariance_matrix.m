function results = get_ard_covariance_matrix(X,Y,w0,alpha0,varargin)


%% parse input
% =============

  if nargin>=5
    if ismember('plot',varargin)
      toplot = 1;
    else
      toplot = 0;
    end
  else
    toplot = 0;
  end
  
%% set up ASD
% =============

  % key parameters
    MAX_ITERATIONS = 5;
    [N T] = size(X);
    ssq0 = var(Y - w0'*X);  

  % history
    history = struct;
    for ii=1:MAX_ITERATIONS
      history(ii).C = nan;
      history(ii).invC = nan;
      history(ii).S = nan;
      history(ii).mu = nan;
      history(ii).logE = nan;
      history(ii).alpha = nan;
      history(ii).ssq = nan;
    end

  % initial values
    alpha = alpha0;
    ssq = ssq0;
  
  % calculate covariance, mean matrices
    invC  = diag(alpha);
    C     = diag(1./alpha);
    
    S = inv(1/ssq * (X*X') + invC);
    mu = 1/ssq * S * X * Y';
    
  % calculate simplifying terms
    YYt = Y*Y';
    YXt = Y*X';
    XYt = X*Y';
  
  % calculate logE
    try
%       logE = ...
%           0.5*logdet(S) - 0.5*logdet(C) - N/2*log(2*pi*ssq) + ...
%           - 0.5 * 1/(ssq^2) * Y * (ssq*eye(T) - X'*S*X) * Y';
        logE = ...
            0.5*logdet(S) - 0.5*logdet(C) - N/2*log(2*pi*ssq) + ...
            - 0.5 * 1/(ssq^2) * (ssq*YYt - YXt*S*XYt);      
    catch
      logE = nan;
    end
 

  warning off MATLAB:nearlySingularMatrix;

  
%% run iterations
% =================

for ii=1:MAX_ITERATIONS

  % calculate covariance, mean matrices
  % ------------------------------------
    invC  = diag(alpha);
    C     = diag(1./alpha);

    invS = 1/ssq * (X*X') + invC;
       scalefactor.invS = exp(-logdet(invS)/N);
       scaled.invS = invS * scalefactor.invS; 
       scaled.S = inv(scaled.invS);
    S = scaled.S * scalefactor.invS;    

    mu = 1/ssq * S * X * Y';

    
  % calculate logE
  % -------------------
    try
      logE = ...
          - 0.5*logdet(invS) - 0.5*logdet(C) - N/2*log(2*pi*ssq) + ...
          - 0.5 * 1/(ssq^2) * (ssq*YYt - YXt*S*XYt);
    catch
      logE = nan;
    end
    
  % save into history
  % -------------------
  
    history(ii).C = C;
    history(ii).invC = invC;
    history(ii).S = S;
    history(ii).mu = mu;
    history(ii).logE = logE;
    history(ii).alpha = alpha;
    history(ii).ssq = ssq;

    
    
  % plot
  % ------
    if toplot
      plot_ongoing_results(history,ii);
    end
    
  % next step
  % -----------
    ssq = (Y - mu'*X)*(Y - mu'*X)' / ( T - trace(eye(N) - S*invC) );
    alpha = ((1 - diag(S) .* alpha) ./ (mu.^2));

end % of iterations


%% parse results
% ================
  results = history(ii);

end



%% ========================================================
function plot_ongoing_results(history,ii)
  figure(1);
  subplot(1,1,1);
    plot(1:L(history), [history.logE],'bo-');
    legend('logE','location','southeast');
  drawnow;
end      
