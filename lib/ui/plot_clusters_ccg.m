function p = plot_clusters_ccg(data,acgs,cols,ctp)

% parse input
n.c = L(data);
if nargin<4
  ctp = 1:n.c;
end
n.ctp = L(ctp);

% parse data
d = cell(1,n.ctp);
for ii=1:n.ctp
  d{ii} = data(ctp(ii)).set;
end

% check that they are the same length
if ~(L(unique(Lincell(d)))==1)
  warning('ccg:fail','data sets are of different length');
  fprintf('press enter to continue...\n');
  pause;
  p = [];
  return;
end

%% calculate CCGs
% ====================

tt = acgs(1).tt;
tt = [-fliplr(tt) tt(2:end)];
tc = midpoints(tt);

% run through all combos
counts = cell(n.ctp,n.ctp);
for aa=1:n.ctp
  for bb=1:aa
    counts{aa,bb} = 0*tc;
    for ss=1:L(d{1})
      for rr=1:L(d{1}(ss).repeats)
        
        t1 = d{aa}(ss).repeats(rr).t;
        t2 = d{bb}(ss).repeats(rr).t;
        
        try
          dt = [pickall(repmat(t1',1,L(t2)) - repmat(t2',1,L(t1))')];
        catch
          dt = [];
          continue;
        end
        if aa==bb
          dt = dt(~(dt==0));
        end
        if isempty(dt)
          continue;
        end
        try
        counts{aa,bb} = counts{aa,bb} + histc_nolast(dt,tt)';
        catch
        end
      end
    end
  end
end

%% plot
% ======

p = struct;
p.fig = figure;
set(p.fig,'Name','CCG');

switch get_current_computer_name
 case {'macgyver','welshcob'}
    set(p.fig,'position',[1681 1050 1680 1050]);
  otherwise
    h = min(200*n.ctp, 200*n.ctp);
    w = h;
    set_fig_size(w,h,p.fig);
    put_fig_in_top_right;
end

for aa=1:n.ctp
  for bb=1:aa
    
    cl1 = ctp(aa);
    cl2 = ctp(bb);
    if (aa==bb)
      col = cols(cl1,:);
    else
      col = 'k';
    end
    
    axn(n.ctp,n.ctp,aa,bb,'gapx',0.2,'gapy',0.2);
    p.h(aa,bb) = bar(tc,counts{aa,bb},'facecolor',col,'linestyle','none','barwidth',1);
    
    ylim( [0 1+max(counts{aa,bb})] );
    xlim(minmax(tt));
    
    set(gca,'xtick',min(tt):2:max(tt),'xticklabel',{},'ytick',[]);
    
    if (aa==bb)
      title10bf(['C ' n2s(cl1)]);
    else
      title10bf(['C ' n2s(cl1) ' - C ' n2s(cl2)]);
    end
    
  end
end
  