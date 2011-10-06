function p = plot_clusters_time_changes(sweep_count,cols,clusters_to_plot)

p = struct;
p.fig = figure;
w = 600; h = 800;

% fig position
switch get_current_computer_name
  case {'macgyver','welshcob'}
    set(p.fig,'position',[2680 1050 w h]);
  case 'blueweasel'
    set(p.fig,'position',[2830 0 512 1120]);
  case 'chai'
    set(p.fig,'position',[1682 30 216 889]);
  otherwise
    set(p.fig, 'outerposition', choosefigpos(4));
  end

set(p.fig,'Name','Events over time');

n.c = L(sweep_count);
n.sweeps = L(sweep_count{1});

if nargin<3
  clusters_to_plot = 1:n.c;
end
n.ctp = L(clusters_to_plot);


for cc=1:n.ctp
  cl = clusters_to_plot(cc);
  
  % make axis
  axn(n.ctp,1,cc,1,'gapx',0.08,'gapy',0.08);
  hold on;
  
  % plot
  h = sweep_count{cl};
  plot(1:n.sweeps, h, 'o', 'color', cols(cl,:),'linewidth',1);
  plot(1:n.sweeps, smooth(h,10), '-', 'color', 'k','linewidth',2);
  
  % aesthetics
  ylim([0 1+max(h)*1.05]);
  xlim([1 n.sweeps]);
  noticks;
  
  % labels
  ylabel10bf(['C ' n2s(cl)]);
end

