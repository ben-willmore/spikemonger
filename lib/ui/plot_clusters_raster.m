function p = plot_clusters_raster(data, cols, ctp)


  n.ctp = L(ctp);
  cc = 1;
  cl = ctp(cc);
  
  d = data(cl).set;
  
  p = struct;
  p.fig = figure(100); clf;
  
  w = 800; h = 950;

% fig position
switch get_current_computer_name
  case {'macgyver','welshcob'}
    set(p.fig,'position',[3360-w 1050 w h]);
  case 'blueweasel'
    set(p.fig,'position',[2830 0 512 1120]);
  otherwise
    set_fig_size(w,h,p.fig);
    put_fig_in_top_right;
  end

set(p.fig,'Name','Raster');


  p.ax(cc) = ax(1,2,cc,'gapx',0.2,'gapy',0.05,'offset',[0.05 0 0 0]);
  hold on;
  
  y = []; t = [];
    y_curr = 0;
  for ss=1:L(d)
  
  t = [t d(ss).spikes.t];
  y = [y y_curr-d(ss).spikes.repeat_id];  
  
  y_curr = y_curr - L(d(ss).repeats) - 1;
  plot([0 1e6],y_curr*[1 1],'k');
  end
  
  plot(t,y,'.','color',cols(cl,:));
  xlim([0 max(t)*1.01]);
  noticks;
  title12bf('by set');
  
  p.ax(2) = ax(1,2,2,'gapx',0.2,'gapy',0.05,'offset',[0.05 0 0 0]);

  r = [d.repeats];
  [ts sort_idx] = sort({r.timestamp});
  for ii=1:L(r)
    idx = sort_idx(ii);
    r(idx).sweep_id = 0*r(idx).t + ii;
  end
  y = -[r.sweep_id];
  t = [r.t];
  plot(t,y,'.','color',cols(cl,:));
   xlim([0 max(t)*1.01]);
  noticks;
  title12bf('by time');