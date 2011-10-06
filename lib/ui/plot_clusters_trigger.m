function p = plot_clusters_trigger(trig, cols, clusters_to_plot, n)

%%
p = struct;
p.fig = figure;
set(p.fig,'Name','triggers');

if nargin<3
  clusters_to_plot = 1:n.c;
end
n.ctp = L(clusters_to_plot);

w = 150;
h = min(800, 100*n.ctp);
switch get_current_computer_name
  case 'blueweasel'
    set(p.fig,'position',[3345 0 175 1120]);
  otherwise
    set(p.fig, 'outerposition', choosefigpos(5));
end

for cc=1:n.ctp
  cl = clusters_to_plot(cc);
  col = cols(cl,:);
  
  % create plot
  axn(n.ctp,1,cc,1,'gapx',0.2,'gapy',0.05,'offset',[0.05 0 0 0]);

  % histogram
  h = hist(trig{cl},1:n.channels);
  p.h(cc) = bar(1:n.channels,h,'facecolor',col,'linestyle','none','barwidth',1);

  % aesthetics
  xlim([1 n.channels]);
  set(gca,'xtick',0:1:n.channels,'xticklabel',{},'ytick',[]);

  % labels
  ylabel10bf(['C ' n2s(cl)]);  

end
