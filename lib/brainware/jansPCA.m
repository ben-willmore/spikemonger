function [W,D]=jansPCA(X);
% PCA of X, theory as described in Hyvaerinen et al
% "independent component analysis", pages 126f.
% for ii=1:size(X,1),
%     X(ii,:)=X(ii,:)-mean(X(ii,:));
%     X(ii,:)=X(ii,:)./norm(X(ii,:));
% end;


C=cov(X);
[W,D]=eig(C,'nobalance');
% we now have the weigths for the principle components in W, the ii-th column corresponding to
% the weights for the ii-th principle component 
% We'd like them to be sorted in order of eigenvalues

S=[-diag(D)';W];
S=sortrows(S',1)';
D=-S(1,:);
W=S(2:end,:);

% % If I now wanted to "pc analyse" the ii-th data point I would do this by:
% ii=10;
% y=W'*X(ii,:)'; % then the elements of y tell us how much we have of each of the PCAs in X(ii,:)
% % we can then reconstitute the ii-th data set simply by
% Xreconst=W*y; 