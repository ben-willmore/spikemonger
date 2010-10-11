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

system(['lib/klustakwik/KlustaKwik ./.temp/X_' randstr ' 1' ...
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

if subset_size==1
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
    W = []; M = []; V = [];
  end
  
else
  
  W = [];
  M = [];
  V = [];
end

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