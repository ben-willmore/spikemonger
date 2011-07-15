function p = plot_clusters_fsp_separation(fsp, cols, ctp)

%% parse input
n.c = L(fsp);
if nargin<3
  ctp = 1:n.c;
end
n.ctp = L(ctp);

%% calculate separation

p = struct;
p.fig = figure;
set(p.fig,'Name','FSP separation');

switch get_current_computer_name
 case {'macgyver','welshcob'}
    set(p.fig,'position',[1681 1050 600 600]);
  otherwise
    h = min(200*n.ctp, 200*n.ctp);
    w = h;
    set_fig_size(w,h,p.fig);
    put_fig_in_top_right;
end

projections = cell(n.ctp, n.ctp);
for ii=1:n.ctp
  for jj=(ii+1):n.ctp
   
    axn(n.ctp-1, n.ctp-1, ii, jj-1, 'gapx',0.2,'gapy',0.2);
    hold on;
    
    % which clusters
    [c, proj, count, centre] = IA(cell(1, 2));
    c{1} = ctp(ii);
    c{2} = ctp(jj);
    % calculate approximate separation axis
    axis = mean(fsp{c{1}}) - mean(fsp{c{2}});
    axis = axis(1:end-1);
    % project onto this axis
    for kk=1:2
      proj{kk} = fsp{c{kk}}(:, 1:end-1) * axis';
    end
    
    edge_min = min(cell2mat(proj(:)));
    edge_max = max(cell2mat(proj(:)));
    edges = linspace(edge_min, edge_max, 40);
    spacing = edges(2) - edges(1);
    centres = midpoints(edges);
    centres = [centres(1) - spacing, centres, centres(end) + spacing];

    for kk=1:2
      count{kk} = histc_nolast(proj{kk}, edges)';
      count{kk} = [0 count{kk} 0];
    end
    % plot these
    plot(centres, count{1} + count{2}, 'color', 0.4*[1 1 1], 'linewidth', 3);
    for kk=1:2
      plot(centres, count{kk}, 'color', 'k', 'linewidth', 5);
    end
    for kk=1:2
      plot(centres, count{kk}, 'color', cols(c{kk}, :), 'linewidth', 3);
    end
    % limits
    xl = [min(centres) max(centres)];
    xlim(xl);
    % titles
    title16bf(['C ' n2s(c{1}) '   vs.   C ' n2s(c{2})]);
    
    
  end
end

%%

cols(c{1}, :)



