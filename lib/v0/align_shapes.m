function sh = align_shapes(shapes,features)
  % shapes = align_shapes(shapes)
  %
  % aligns shapes based on their cross-correlation, so that PCA analysis
  % can be performed on them

  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

%% prelims

n.shapes = size(shapes,2);
if n.shapes==0
  sh.original = [];
  sh.normalised = [];
  sh.aligned = [];
  sh.pca_projection = [];
  return;
end


if nargin==1
  features = struct;
  features.energy                       = var(shapes);  
  [features.peakmax features.peakmaxt]  = max(shapes);
  [features.peakmin features.peakmint]  = min(shapes);
  features.area_peak                    = sum(shapes .* (shapes>0));
  features.area_valley                  = sum(shapes .* (shapes<0));
end  




%% compute cross-correlations

% structure
  sh = struct;
  sh.original = shapes;
  shape_length = size(shapes,1);
	sh.normalised = shapes - repmat(mean(shapes,1),shape_length,1);

% reference shape
  sh.ref      = mean(sh.original,2);
  sh.ref_norm = sh.ref - mean(sh.ref);

% compute cross-correlations

  M = zeros(shape_length,21);
  for ii=1:21
    jj = ii-11;
    rnt = circshift(sh.ref_norm,jj);
    if jj>0
      rnt(1:jj) = 0;
    elseif jj<0
      rnt((end+jj+1):end) = 0;
    end
    M(:,ii) = rnt / (shape_length - abs(jj));
  end
  M = M';

% align
  [ccs bestlag] = max((M * sh.normalised));
  sh.sum_ccs = sum(ccs);

  sh.aligned = nan*[zeros(10,size(sh.original,2)); zeros(size(sh.original)); zeros(11,size(sh.original,2))];
  for ii=1:size(sh.original,2)
    sh.aligned( (1:shape_length)+22-bestlag(ii), ii) = sh.original(:,ii);
  end
  

% attempt this again

for hh=2:3
  % structure
    sh(hh).original    = sh(hh-1).original;
    sh(hh).normalised  = sh(hh-1).normalised;

  % reference shape
    sh(hh).ref      = sh(hh-1).aligned;
      sh(hh).ref( isnan(sh(hh).ref) ) = 0;
      sh(hh).ref = mean(sh(hh).ref,2);
    sh(hh).ref_norm = sh(hh).ref - mean(sh(hh).ref);

  % compute cross-correlations
    M = zeros(shape_length,21);
    for ii=1:21
      jj = ii-11;
      rnt = circshift(sh(hh).ref_norm,jj);
      if jj>0
        rnt(1:jj) = 0;
      elseif jj<0
        rnt((end+jj+1):end) = 0;
      end
      M(:,ii) = rnt(12:(11+shape_length)) / (shape_length - abs(jj));
    end
    M = M';

  % align
    [ccs bestlag] = max((M * sh(hh).normalised));
    sh(hh).sum_ccs = sum(ccs);

    sh(hh).aligned = nan*[zeros(10,size(sh(hh).original,2)); zeros(size(sh(hh).original)); zeros(11,size(sh(hh).original,2))];
    for ii=1:size(sh(hh).original,2)
      sh(hh).aligned( (1:shape_length)+22-bestlag(ii), ii) = sh(hh).original(:,ii);
    end
end

sh = sh(3);

%% for pca: set all the nans to mean value
  sh.for_pca = sh.aligned;
  meansh = nanmean(sh.for_pca,2);
  meansh(isnan(meansh)) = 0;
  for ii=1:size(sh.for_pca,1)
    sh.for_pca(ii,isnan(sh.for_pca(ii,:))) = meansh(ii);
  end
    
%% eigendecomposition

[V D] = eig(cov(sh.for_pca'));
D = fliplr(diag(D)');
V = fliplr(V);

%% plots

n.t = size(sh.for_pca,1);
n.spikes = size(sh.for_pca,2);

% clf; hold on;
% plot(1:n.t,meansh,'color',[0 0 0],'linewidth',3);
% plot(1:n.t,V(:,1)*D(1)/30,'color','r');
% plot(1:n.t,V(:,2)*D(2)/30,'color','b');
% plot(1:n.t,V(:,3)*D(3)/30,'color','g');

%% projections

sh.pca_projection = (sh.for_pca' * V)';
%figure(5);
%plot3(sh.pca_projection(:,1),sh.pca_projection(:,2),sh.pca_projection(:,3),'b.');

end