function Wa=adaptivePCA(X,iter, learningRate, decayRate);
% try to learn the first numComp principal components of data matrix X by iterative learning
% and Oja's rule
numComp=4;
% 
% nval=mean(X);
% for ii=1:size(X,1),
%     X(ii,:)=X(ii,:)-mean(X(ii,:));
%     X(ii,:)=X(ii,:)./norm(X(ii,:));
% end;

% Wa=ones(numComp,size(X,2));
Wa(1,:)=mean(X); 
% %Wa(1,:)=mean(X)/10; 
Wa(2,:)=-Wa(1,:);
Wa(3,:)=Wa(2,:)-Wa(1,:);
Wa(4,:)=Wa(3,:)-Wa(1,:);

if ~exist('learningRate')
    learningRate=0.1;
end;
if ~exist('iter')
    iter=100;
end;
if ~exist('decayRate')
    decayRate=0.95;
end;

% adapt first principal component
lrate=learningRate;
snapshot1=Wa(1,:);
snapshot2=Wa(2,:);
snapshot3=Wa(3,:);
snapshot4=Wa(4,:);

deltas=ones(1,iter*size(X,1)); jj=1;

lrate=learningRate;
for iteration=1:iter,
   if mod(iteration,2)==1, 
       snapshot1=[snapshot1; Wa(1,:)];
       snapshot2=[snapshot2; Wa(2,:)];
       snapshot3=[snapshot3; Wa(3,:)];
       snapshot3=[snapshot4; Wa(4,:)];
   end;    
   for ii=1:size(X,1),
        x=X(ii,:); % x is the ii-th data vector;
        y(1)=Wa(1,:)*x';
        y(2)=Wa(2,:)*x';
        y(3)=Wa(3,:)*x';
        y(4)=Wa(4,:)*x';
        % adapt first principal component
        deltaW=(y(1)*x-y(1)^2*Wa(1,:));
        Wa(1,:)=Wa(1,:)+lrate*deltaW;
        % adapt 2nd principal component
        Wa(2,:)=Wa(2,:)+(lrate)*y(2)*(x-y(2)*Wa(2,:)-2*y(1)*Wa(1,:));
        % adapt 3rd principal component
        Wa(3,:)=Wa(3,:)+(lrate)*y(3)*(x-y(3)*Wa(3,:)-2*(y(1)*Wa(1,:)+y(2)*Wa(2,:)));
        % adapt 4th principal component
        Wa(4,:)=Wa(4,:)+(lrate)*y(4)*(x-y(4)*Wa(4,:)-2*(y(1)*Wa(1,:)+y(2)*Wa(2,:)+y(3)*Wa(3,:)));
        deltas(jj)=norm(Wa(3,:)-y(3)*(x-y(3)*Wa(3,:)-2*(y(1)*Wa(1,:)+y(2)*Wa(2,:)))); jj=jj+1;
    end;
    lrate=lrate*decayRate;
end;

% lrate=learningRate;
% for iteration=1:iter,
%    if mod(iteration,2)==1, 
%        snapshot3=[snapshot3; Wa(3,:)];
%    end;    
%    for ii=1:size(X,1),
%         x=X(ii,:); % x is the ii-th data vector;
%         y(1)=Wa(1,:)*x';
%         y(2)=Wa(2,:)*x';
%         y(3)=Wa(3,:)*x';
%         % adapt 3rd principal component
%         Wa(3,:)=Wa(3,:)+(lrate)*y(3)*(x-y(3)*Wa(3,:)-2*(y(1)*Wa(1,:)+y(2)*Wa(2,:)));
%         deltas(jj)=norm(Wa(3,:)-y(3)*(x-y(3)*Wa(3,:)-2*(y(1)*Wa(1,:)+y(2)*Wa(2,:)))); jj=jj+1;
%     end;
%     lrate=lrate*decayRate;
% end;

clf;
subplot(4,1,1);
imagesc(snapshot1);
subplot(4,1,2);
imagesc(snapshot2);
subplot(4,1,3);
imagesc(snapshot3);
subplot(4,1,4);
plot(snapshot4);