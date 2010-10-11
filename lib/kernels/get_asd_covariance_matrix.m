function results = get_asd_covariance_matrix(X,Y,w0,rho0,di0,varargin)


%% parse input
% =============

  if nargin<4
    rho0 = 1;
    df0 = 1;
  end

  if nargin>=6
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

% fprintf('setting up ASD...\n');

  % key parameters
    eps = 1e-2;
    MAX_ITERATIONS = 200;
    [N T] = size(X);
    ssq0 = var(Y - w0'*X);  

  % distance matrix
    Di = repmat(1:(N-1),(N-1),1);
    Di = (Di - Di').^2;
      % add constant term
        Di = [Di inf(N-1,1); inf(1,N-1) 0];
      % version with no infinites
	Di_noinfs = Di; 
	Di_noinfs(~isfinite(Di_noinfs))=0;

  % history
    history = struct;
    for ii=1:MAX_ITERATIONS
      history(ii).C = nan;
      history(ii).invC = nan;
      history(ii).S = nan;
      history(ii).mu = nan;
      history(ii).logE = nan;
      history(ii).rho = nan;
      history(ii).di = nan;
      history(ii).ssq = nan;
      history(ii).eps = eps;
    end

  % initial values
    rho = rho0;
    di = di0;
    ssq = ssq0;
  
  % calculate covariance, mean matrices
    C = exp( - rho - 0.5*Di/(di^2) );
    S = inv(1/ssq * (X*X') + inv(C));
    SX = (1/ssq * (X*X') + inv(C)) \ X;
    mu = 1/ssq * SX * Y';
    
  % calculate simplifying terms
    YYt = Y*Y';
    YXt = Y*X';
    XYt = X*Y';
  
  % calculate logE
    try
%       logE = ...
%           0.5*logdet(S) - 0.5*logdet(C) - N/2*log(2*pi*ssq) + ...
%           - 0.5 * 1/(ssq^2) * Y * (ssq*eye(T) - X'*SX) * Y';
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
    C = exp( - rho - 0.5*Di/(di^2) );
      % C( log10(C)<-8 ) = 0;
      scalefactor.C = exp(-logdet(C)/N);
      scaled.C = C * scalefactor.C; 
      scaled.invC = inv(scaled.C);
    invC = scaled.invC * scalefactor.C;
    invS = 1/ssq * (X*X') + invC;
       scalefactor.invS = exp(-logdet(invS)/N);
       scaled.invS = invS * scalefactor.invS; 
       scaled.S = inv(scaled.invS);
    S = scaled.S * scalefactor.invS;    

    mu = 1/ssq * S * X * Y';
    if any(isnan(mu))
      keyboard;
    end

    
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
    history(ii).rho = rho;
    history(ii).di = di;
    history(ii).ssq = ssq;


  % check that there's been an improvement
  % ----------------------------------------
    toskip = 0;
    if ii>1
      if ~isnan(logE)
        if ~(logE > history(ii-1).logE)
          history(ii).rho = history(ii-1).rho;
          history(ii).di  = history(ii-1).di;
          history(ii).ssq = history(ii-1).ssq;
          history(ii+1).eps = history(ii).eps/2;
          history(ii).eps   = 0;
          history(ii).logE = history(ii-1).logE;
          toskip = 1;
        end
      end
    end
    
    
  % plot
  % ------
    if toplot
      plot_ongoing_results(history,ii);
    end


  % finish early, if necessary
  % -----------------------
    if ii<MAX_ITERATIONS
      if log10(history(ii+1).eps)<-8
      	break;
      elseif toskip
      	continue;
      end
    end

    
  % next step
  % -----------
    Q = C - S - mu*mu';
    d.rho = 0.5*trace(Q*invC);
    d.di  = -0.5/(di^3) * trace(Q*invC*(Di_noinfs.*C)*invC);
    eps = history(ii).eps;
    if (di + eps*d.di)<1e-2
      if ~(d.di==0)
        eps = (1e-2 - di)/d.di;
        history(ii).eps = eps;
      end
    end
    rho = rho + eps*d.rho;
    di  = di + eps*d.di;    
    ssq = (Y - mu'*X)*(Y - mu'*X)' / ( T - trace(eye(N) - S*invC) );


end % of iterations


%% parse results
% ================
  results = history(ii);

end



%% ========================================================
function plot_ongoing_results(history,ii)
  figure(1);
  subplot(3,1,1);
    plot(1:L(history), [history.logE],'bo-');
    legend('logE','location','southeast');
  subplot(3,1,2);
    plot(1:L(history), [history.rho],'rx-', 1:L(history), [history.di],'ms-');
    legend({'rho','di'},'location','southeast');
  subplot(3,1,3);
    toplot = [history.eps];
    toplot(ii+1:end) = nan;      
    plot(1:L(history), toplot,'d-','color',[0 0.6 0]); 
      ylim([0 max(toplot)]*1.1); 
      xlim([0 L(history)]);
    legend('log(eps)','location','southeast');
  drawnow;
end      
