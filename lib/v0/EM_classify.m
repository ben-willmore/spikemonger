function [C P best_P NStds best_NStds] = EM_classify(X, W, M, V)
  % [C P best_P NStds best_NStds] = EM_classify(X, W, M, V)
  %
  % EM classification function. Takes the outputs of the EM algorithm and
  % determines to which 
  %   - artefact rejection
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)



% dimensions
  N = size(X,1);
  d = size(X,2);
  k = length(W);

% initialise  
  P = nan * zeros(N,k);
  NStds = P;  
  C = nan * zeros(N,1);
  best_P     = C;
  best_NStds = C;
  
  Vinv        = zeros(d,d,k);
  Pmultiplier = zeros(1,k);
  for cc=1:k
    Vinv(:,:,cc)    = inv( V(:,:,cc) );
    Pmultiplier(cc) = (2 * pi)^(-1/2 * d) * det(V(:,:,cc))^(-1/2)  * W(cc);
  end  
  Pmultiplier = repmat(Pmultiplier,N,1);   
  
  
  % probabilities for each cluster
    for cc=1:k
      XM = X - repmat( M(:,cc)', size(X,1), 1 );
      Vi = Vinv(:,:,cc);
      NStds(:,cc) = sqrt( sum( (XM * Vi) .* XM , 2) );
    end
  P = Pmultiplier .* exp(-0.5 * NStds);
  
  % assign clusters
    [best_P C] = max(P,[],2);
    best_NStds = NStds( (C-1)*N + (1:N)' );
  
end
     