function p = plot_clusters_waveforms(sh, sh_mean, cols, clusters_to_plot, sweep_count, shape_correlation)

% parameters
n.c = L(sh);
n.pts = size(sh{1},2);
n.ch = size(sh{1},3);

if nargin<4
  clusters_to_plot = 1:n.c;
end

channels_to_plot = 1:n.ch;
points_to_plot = 1:n.pts;


% figure
p = struct;
p.fig = figure;
set(p.fig,'Name','Waveforms');
w = min(800,200*L(clusters_to_plot));
h = 1000;

% fig position
switch get_current_computer_name
  case {'macgyver','welshcob'}
    set(p.fig,'position',[1680-w 1050 w h]);
  case 'blueweasel'
    set(p.fig,'position',[1080 0 w h]);
  otherwise
    set(p.fig, 'outerposition', choosefigpos(1));
end

% limits
xl = [points_to_plot(1) points_to_plot(end)] + 0.5*[-1 1];
yl = max(cell2mat(map_to_cell(@(x) max(abs(x(:))), sh)'));
yl = min(yl, median(cell2mat(map_to_cell(@(x) max(abs(x(:))), sh)'))*1.5);
yl = yl*[-1 1];

% count
n.ctp = L(clusters_to_plot);
n.ch_tp = L(channels_to_plot);

% run through clusters
for cc=1:n.ctp
  cl = clusters_to_plot(cc);
  col = cols(cl,:);
    
  % run through channels
  for ii=1:n.ch_tp
    
    % create axis
    p.ax(cc,ii) = axn(n.ch_tp,n.ctp,ii,cc,'gapx',0.1,'gapy',0.1,'offset',[0.025 0.025 0 0.05]);
    hold on;

    % plot shapes
    try
      [t s] = get_shape_plot_data(sq(sh{cl}(1:10,:,ii))');
      p.shapes(cc,ii) = plot(t,s,'color',col);
      p.mean(cc,ii) = plot(1:40,sh_mean{cl}(:,ii),'k','linewidth',2);
    catch
    end
    
    % set limits
    xlim(xl);
    ylim(yl/2);
    
    % title
    if ii==1
      title10bf(['C ' n2s(cl)]);
    end
    
    % axis label
    if cc==1
      ylabel10bf(['E ' n2s(ii)]);
    end
    if ii==n.ch_tp
      xlabel10bf(...
        {n2s(nansum(sweep_count{cl})), ...
        ['r = ' n2s(round(shape_correlation(cl)*100)/100)]});
    end
    
  end
end
