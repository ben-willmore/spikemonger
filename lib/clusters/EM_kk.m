function clusters = EM_kk(fsp, varargin)
  % data = EM_kk(fsp)
  %
  % Runs EM on the data, using the feature space (fsp) provided
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 26-May-2010
  %   - distributed under GPL v3 (see COPYING)
  

%% compute
% ===========

% source data
X = 1000*fsp;
D = size(X,2);


% will we be creating a file bigger than 2GB?
N = numel(X);
if N>1.23e8  
  fprintf_bullet('file will be 2GB, have to reduce the number of dims\n',1);
  dims_to_keep = sort([1:3:D 2:3:D]);
  X = X(:,dims_to_keep);
  D = size(X,2);  
end

% write source data
randstr = n2s(round(rand*1e8));
mkdir_nowarning('.temp');
filename = ['.temp/X_' randstr '.fet.1'];
fid = fopen(filename,'w');
fprintf(fid,'%s\n',n2s(D));
fclose(fid);
save(['.temp/X_' randstr '.fet.1'],'X','-ASCII','-append');

% use a subset?
if size(X,1) > 50e3
  subset_size = ceil(size(X,1) / 50e3);  
else
  subset_size = 1;
end

%% execute kk
if ispc
  suffix = '.exe';
else
  suffix = '';
end

executable = ['lib/klustakwik/' computer '/KlustaKwik' suffix];
system([executable ' ./.temp/X_' randstr ' 1' ...
          ' -UseFeatures ' repmat('1',1,D) ...          
          ' -Subset ' n2s(subset_size) ...
          ' -MaxClusters 24' ...
          ]);


%% read cluster results
% ======================

% read
fid = fopen(['.temp/X_' randstr '.clu.1'],'rt');
C = textscan(fid,'%s','bufsize',1e6); C = C{1};
fclose(fid);

% parse
C = str2double(C);
n.clusters = C(1);
C = C(2:end);

%% read clustering parameters
% =============================

if false %subset_size==1
  try
    % read
    fid = fopen(['.temp/X_' randstr '.param.1'],'rt');
    P = textscan(fid,'%s','bufsize',1e6); P = P{1};
    fclose(fid);
    
    % parse
    pos = struct;
    pos.class   = find(ismember(P,'Class:'));
    pos.weight  = find(ismember(P,'Weight:'));
    pos.mean    = find(ismember(P,'Mean:'));
    pos.cov     = find(ismember(P,'Cov:'));
    
    % check that the number of clusters is identical
    if ~(n.clusters == L(pos.class))
      warning('cluster:problem',['not the same number of clusters in the' ...
        ' .clu and .param files']);
      keyboard;
    end
    
    %ns = str2double(C(pos.class+1));
    W = str2double(P(pos.weight+1));
    
    M = nan(D, n.clusters);
    for ii=1:n.clusters
      M(:,ii) = str2double(P(pos.mean(ii) + (1:D)));
    end
    
    V = nan(D, D, n.clusters);
    for ii=1:n.clusters
      V(:,:,ii) = reshape(str2double(P(pos.cov(ii) + (1:(D^2)))),D,D)';
    end
    
  catch
    keyboard;
    W = []; M = []; V = [];
  end
  
else
  
  W = [];
  M = [];
  V = [];
  
end

%% recalculate cluster statistics
% =================================


% get cluster data
n.u = size(fsp,1);
n.dims = size(fsp,2);

% preconstruct
W = nan(1, n.clusters);
M = nan(n.dims, n.clusters);
V = nan(n.dims, n.dims, n.clusters);

% constant cluster
W(1) = (sum(C==1)+1) / (n.u + 1);  % added one for the noise point

% main clusters
for ii=2:n.clusters
  
  tok = (C==ii);
  W(ii) = sum(tok) / (n.u + 1);  % added one for the noise point
  M(:,ii) = mean(fsp(tok,:))';
  V(:,:,ii) = cov(fsp(tok,:));
  
end

%% recalculate W(1)
% ===================

% for some reason, the calculation above does not work for the
% constant class, but it does work for all the others.
%
% ie it can replicate the values of the probabilities for the
% non-constant (gaussian) classes, but not for the constant
% class. To find the appropriate setting for the constant
% class, the appropriate weight for the constant class is
% guessed based on klustakwik's cluster assignment.

% calculate logP for training data
logP = nan(n.clusters, n.u);
for cc=2:n.clusters
  w = W(cc);
  m = M(:,cc);
  v = V(:,:,cc);
  x = (fsp - repmat(m',n.u,1))';
  logP(cc,:) = -0.5 * sum(x .* (v\x)) - 0.5*logdet(v) - 0.5*n.dims*log(2*pi);
end

% look at those for whom cluster 1 was assigned
% to set an upper limit for logP for the constant class
upper_limit = maxall(logP(2:end, C==1));

% look at those for whom other clusters were assigned
% to set a lower limit for logP for the constant class
lower_limit = min(max(logP(2:end, ~(C==1))));

% bisect and exponentiate to get W(1)
W(1) = exp(0.5*(lower_limit + upper_limit));


%% prepare output
% =================

clusters = struct;
clusters.n_clusters = n.clusters;
clusters.dim = D;
clusters.C = C;
clusters.W = W;
clusters.M = M;
clusters.V = V;

% delete temp files
delete(['.temp/X_' randstr '*']);