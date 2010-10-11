function p = plot_clusters_psth_all(psth,sve,cols,clusters_to_plot)

%% parameters
n.c = L(psth);

if nargin<4
  clusters_to_plot = 1:n.c;
end
n.ctp = L(clusters_to_plot);

%% plot

% figure
p.fig = figure;
set(p.fig,'Name','PSTHs');
w = 600;
h = min(800,200*n.ctp);

% position
switch get_current_computer_name
  case {'macgyver','welshcob'}
    set(p.fig,'position',[1680 1050 w h]);
  case 'blueweasel'
    set(p.fig,'position',[1600 0 670 1120]);
  case 'chai'
    set(p.fig,'position',[804 6 548,963]);
  otherwise
    set_fig_size(w,h,p.fig);
    put_fig_in_top_right;
  end

% run through different bin widths
dhs = [2 5 10 25];
for cc = 1:n.ctp
  for hh=1:L(dhs);
    dh = dhs(hh);
    cl = clusters_to_plot(cc);
    col = cols(cl,:);
    
    % make axis
    p.ax(cc,hh) = axn(n.ctp,4,cc,hh,'gapx',0.05,'gapy',0.05,'offset',[0.02 0 0 0.02]);
    
    % plot psth
    tt = psth(cl).(['tt_' n2s(dh) 'ms_bins']);
    count =  psth(cl).(['count_' n2s(dh) 'ms_bins']);
    p.p(cc,hh) = bar( tt, count, ...
      'facecolor',col, 'linestyle','none','barwidth',1);        
    
    % aesthetics
    dt = (tt(2)-tt(1));
    xlim([tt(1)-dt/2 tt(end)+dt/2 ]);
    noticks;
    
    % title
    if hh==1
      p.yl(cc) = ylabel10bf(['C ' n2s(cl)]);
    end
    if cc==1
      p.title(hh) = title10bf([n2s(dh) 'ms bins']);
    end
    
        % sahani variance explained
    sves = reach(sve,['percentage_signal.at_' n2s(dh) 'ms']);
    if all(isnan(sves))
      try
        sves = reach(sve,['pooled.percentage_signal.at_' n2s(dh) 'ms']);
      catch
      end
    end
    
    % print sahani variance explained
    sig = sves(cl);
    sig = round(sig*10)/10;
    sig = ['SP = ' n2s(sig) '%'];
    xl = xlim; yl = ylim;
    p.sve(cc,hh) = text( max(tt)*0.02, max(count)*1.1, sig, ...
      'fontweight','bold', 'verticalalignment','top');
    ylim([0 max(max(count)*1.12,1)]);

  end
  
end


