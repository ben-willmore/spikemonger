function p = plot_clusters_in_fsp(fsp, cols, clusters_to_plot, axes_to_plot)

n.c = L(fsp);
n.dims = size(fsp{1},2);

% what to plot
if nargin<3
  clusters_to_plot = 1:n.c;
end

if nargin<4
  axes_to_plot = 1:n.dims;
end

n.ax = L(axes_to_plot);


% plot
p = struct;
p.fig = figure;
set(p.fig,'Name','Feature space');
set_fig_size(1000,1000,p.fig);
p.p = nan(n.ax-1,n.ax-1,n.c);

for ii=1:(n.ax-1);
  for jj=(ii+1):n.ax
    % construct axis
    p.a(ii,jj) = axn(n.ax-1,n.ax-1,jj-1,ii,'gapx',0.05,'gapy',0.05,'offset',[0.05 0.05 0 0]);
    if jj==n.ax, xlabel8bf(n2s(axes_to_plot(ii))); end
    if ii==1, ylabel8bf(n2s(axes_to_plot(jj))); end
    hold on;
    
    % plot
    for cc=clusters_to_plot
      try
      p.p(ii,jj,cc) = plot( fsp{cc}(:,axes_to_plot(ii)), fsp{cc}(:,axes_to_plot(jj)),...
        '.', 'color', cols(cc,:), 'markersize', 1 );
      catch
      end
    end
  end
  
end

% legend
p.corner = ax(3,3,1,3,'gapx',0.2,'gapy',0.2);
box off;
axis off;
noticks;
hold on;
for cc=1:n.c;
  plot([0 0],[0 0],'.','markersize',6,'color',cols(cc,:));
end
xlim([1 2]); ylim([1 2]);
p.legend = legend(map_to_array(@(x) ['C ' n2s(x)], 1:n.c));
set(p.legend,'box','off');
