%  experimental code. Read a datafile, collect aps and work toward
%  automatic spike sorting.

%d=readSRCfile('C:\jan\guineaPig\413\G1_4strf09.src');
d=readSRCfile('C:\jan\guineaPig\413\G1_4strf04.src');

shapes=[];
for ss=1:length(d.sets),    
    if ~isempty(d.sets(ss).unassignedSpikes.spikes)
        shapes=[shapes [d.sets(ss).unassignedSpikes.spikes.shape]];
    end;
    if ~isempty(d.sets(ss).clusters.sweeps(1).spikes)
        shapes=[shapes [d.sets(ss).clusters.sweeps(1).spikes.shape]];
    end;
end;

X=shapes(1:30,9001:10400)';
X=X./max(max(X));
meanX=mean(X);
for ii=1:size(X,1),
    X(ii,:)=X(ii,:)-meanX;
end;
clf; plot(X'+meanX'*ones(1,1400));

[pca,eigvals]=jansPCA(X);

figure(1); clf;
pc1=adaptivePCA(X,200,0.05,0.99);
figure(2);
subplot(3,1,1);
plot(pca(:,1:4))
subplot(3,1,2);
plot(pc1'); legend('First','Second','Third','fourth',4);
subplot(3,1,3);
plot(pca(:,1:4)-pc1'); title ('difference');


% figure(3);
% pc1=adaptivePCA(shapes(:,1:200)',1000,0.001,0.995);
% title('1000');
% figure(4);
% subplot(2,1,1);
% plot(pca(:,1:3))
% subplot(2,1,2);
% plot(pc1')
% title('1000');
% 

x1=X*pc1(1,:)';
x2=X*pc1(2,:)';
x3=X*pc1(3,:)';
x4=X*pc1(4,:)';

xa1=X*pca(:,1);
xa2=X*pca(:,2);
xa3=X*pca(:,3);

figure(3); clf;

subplot(2,2,1);
plot(x1,x2,'.');
subplot(2,2,2);
plot(x1,x3,'.');
subplot(2,2,3);
plot(x1,x3,'.');
subplot(2,2,4);
plot(x1,x4,'.');

% hold on;
% plot(x1,xa2,'r.');
% hold off;
% subplot(1,2,2);

hist(x1);