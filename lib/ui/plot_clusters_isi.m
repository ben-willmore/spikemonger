function p = plot_clusters_isi(isis,cols,clusters_to_plot)

p = struct;
p.fig = figure;
set(p.fig,'Name','ISIs');

% parameters for ACGs
n.c = L(isis);
tt = isis(1).tt;
tc = isis(1).tc;

if nargin<3
  clusters_to_plot = 1:n.c;
end
n.ctp = L(clusters_to_plot);

% figure size
w = 400;
h = min(824, 206*n.ctp);

% fig position
switch get_current_computer_name
  case {'macgyver','welshcob'}
    set(p.fig,'position',[2280 1050 w h]);
  case 'blueweasel'
    set(p.fig,'position',[2280 0 540 1120]);
  otherwise
    set(p.fig, 'outerposition', choosefigpos(3));
  end

for cc=1:n.ctp
  cl = clusters_to_plot(cc);
  col = cols(cl,:);
  
  % create plot
  axn(n.ctp,1,cc,1,'gapx',0.1,'gapy',0.08,'offset',[0 0.03 0 0]);
  
  % histogram
  h = isis(cc).count;
  p.h(cc) = bar(tc,h,'facecolor',col,'linestyle','none','barwidth',1);
  
  % aesthetics
  xlim(minmax(tt));
  xt = 1:max(tt);
  xtl = cell(1,L(xt));
  if cc==n.ctp
    xtl{1} = '1';
    for ii=5:5:max(tt)
      xtl{ii} = n2s(ii);
    end
  end
  set(gca,'xtick',xt,'xticklabel',xtl,'ytick',[]);

  % labels
  ylabel10bf(['C ' n2s(cl)]);
  % proportion less than 1ms
  str = ['< 1ms  =  ' n2s(round(sum(h(tc < 1)) / sum(h) * 1000)/10) ' %'];
  text(0.2,max(max(h)*1.1,0.95), str,'fontweight','bold','verticalalignment','top');
  ylim([0 max(max(h)*1.12,1)]);
end
