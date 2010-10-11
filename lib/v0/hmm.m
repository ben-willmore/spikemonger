function [transition_points logL] = hmm(X,K,starting_mu)
  % [transition_points logL] = hmm(X,K)
  % [transition_points logL] = hmm(X,K,starting_mu)
  %
  % determines the (maximum likelihood) sweeps at which sudden shifts in
  % the spike count occur.
  %

  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)


%% prelims
% =========

  % starting parameters
    N = L(X);
    mu = median(X) * ones(1,K);
    if nargin==3
      mu = starting_mu;
    end
    q = (K-1) / N;

  % max number of repeats of EM algorithm for convergence
    max_repeats = 10;
    logLs = zeros(1,max_repeats);
  
  
%% EM LOOP
% =========

for rr=1:max_repeats;
  
  % precalculate Pxz = p(xn|zn)
    Pxz = zeros(K,N);
    for kk=1:K
      Pxz(kk,:) = poisspdf(X,mu(kk));
    end
    
    
  % ===================
  % EXPECTATION STAGE
  % ===================

  % empty structure for alpha_hat (ah) and beta_hat (bh) and c_n
    ah = zeros(N,K);
    bh = zeros(N,K);
    c  = zeros(N,1);

  % calculate alpha_hat and c
    ah(1,1) = 1;
    c(1)    = Pxz(1,1);
    for n=2:N;    
      atemp = zeros(1,K);
      atemp(1) = Pxz(1,n) * ah(n-1,1)*(1-q);
      for ii=2:K
        atemp(ii) = Pxz(ii,n) * ( ah(n-1,ii-1)*q + ah(n-1,ii)*(1-q) );
      end
      c(n) = sum(atemp);
      if c(n) > 0
        ah(n,:) = atemp / c(n);
      else
        c(n)=c(n-1);
        ah(n,:) = atemp / c(n);
      end
      
    end

  % calculate beta_hat
    bh(N,:) = ones(1,K);
    for n=(N-1):-1:1
      bh(n,K) = 1/c(n+1) * bh(n+1,K) * Pxz(K,n+1) * (1-q);
      for ii=1:(K-1)
        bh(n,ii) = 1/c(n+1) * (...
          bh(n+1,ii) * Pxz(ii,n+1) * (1-q) ...
          + bh(n+1,ii+1) * Pxz(ii+1,n+1) * q );
      end
    end

  % marginals
    g  = ah .* bh;
    xi0 = zeros(K,N);
    xi1 = zeros(K,N);
    for nn=2:N
      for kk=1:(K-1)
        xi0(kk,nn) = c(nn) * ah(nn-1,kk) * Pxz(kk,nn) * (1-q) * bh(nn,kk);
        xi1(kk,nn) = c(nn) * ah(nn-1,kk) * Pxz(kk+1,nn) * q * bh(nn,kk+1);
      end
    end

  % likelihood
    logLs(rr) = sum(log(c));
   
    
  % ====================    
  % MAXIMISATION STAGE
  % ====================

    % calculate q and mu
      xi1s = sum(xi1(:));
      xi0s = sum(xi0(:));
      q = xi1s / (xi1s + xi0s);
      mu = sum(g .* repmat(X',1,K)) ./ sum(g);

      
      
  % exit loop if likelihood improvement is small
  if rr>1
    if abs((logLs(rr)-logLs(rr-1)) / logLs(rr-1)) < 0.01;
      break;
    end
  end

end


%% maximum likelihood solution
% =============================

[prob best_k] = max(g,[],2);
transition_points = find(diff(best_k))+0.5;
logL = logLs(rr);

if ~isfinite(logL) & nargin==2
  starting_mu = median(X) * ones(1,K); 
  if K>1, starting_mu(2) = max(X); end
  if K>2, starting_mu(3) = median(X); end
  if K>3, starting_mu(4) = min(X); end
  [transition_points logL] = hmm(X,K,starting_mu);
  return;
end

end