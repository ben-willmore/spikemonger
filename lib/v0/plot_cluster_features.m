function sp = plot_cluster_features(data,varargin)
  % plot_cluster_features(data)
  % plot_cluster_features(data,'starting_figure',n)
  % plot_cluster_features(...,'show_isi')
  %
  % Function for plotting all the cluster info
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
%% parse varargin
% ================
  
% defaults
  SKIP_ALIGNMENT = 0;
  global zoomlevel
  if isempty(zoomlevel)
    zoomlevel = 0;
  end
  
  show_excision_adjusted_spike_counts = 1;
  global show_isi;
    try 
      if isempty(show_isi), show_isi=0; end
    catch
      show_isi = 0;
    end

% starting figure
  n.fig1 = 1; n.fig2 = 2;
  
  if nargin > 1
    for ii=1:L(varargin)
      if isequal('starting_figure',varargin{ii})
        n.fig1 = varargin{ii+1};
        n.fig2 = n.fig1+1;

      elseif isequal('show_excision_adjusted_spike_counts',varargin{ii})
        show_excision_adjusted_spike_counts = 1;

      elseif isequal('show_isi',varargin{ii})
        show_isi = 1;
        
      end
      
    end
  end

  
%% important parameters
% ======================

  n.clusters = L(data.cluster) - 1;
  X = data.EM.X;
  C = data.EM.C;
  stdmax = data.EM.stdmax;


%% plot spikes in feature space
% ================================

n.dims = L(data.EM.features);

% colours
  colours = { [0.8 0 0], [0 0 0.8], [0.7 0.4 0], [0.2 0.5 0.9], [0 0.4 0], [0.7 0.7 0.2], [0.7 0.2 0.4], [0.2 0.7 0.4] };
  colours = [colours colours];
  colours{n.clusters+1} = [0 1 0];
  
% graph limits
  xmins = min(X) - (max(X)-min(X))*0.02;
  xmaxs = max(X) + (max(X)-min(X))*0.02;

% subplot widths
  spsize.start.x = 0.15;
  spsize.start.y = 0.1;
  spsize.end.x   = 0.95;
  spsize.end.y   = 0.95;
  spsize.gap.x   = 0.01;
  spsize.gap.y   = 0.01;
  spsize.width.x = (spsize.end.x - spsize.start.x - (n.dims-2)*spsize.gap.x) / (n.dims - 1);
  spsize.width.y = (spsize.end.y - spsize.start.y - (n.dims-2)*spsize.gap.y) / (n.dims - 1);  

%close(n.fig1);
figure(n.fig1);
%set(gcf,'position',[2541 5 839 971]);
clf;
try set(gcf,'name',data(1).metadata.filename(1:(end-4))); catch end
sp = nan*zeros(n.dims,n.dims);

for hh=1:(n.dims-1)
  for ii=(hh+1):n.dims

    % marker size
      if size(X,1)>500
        marker_size = 3;
      else
        marker_size = 6;
      end
    
    sp(hh,ii) = subplot(n.dims-1, n.dims-1, hh + (ii-2)*(n.dims-1));
    hold on;
        
    % unclassified
      %keyboard;
      plot(...
        X(C==(n.clusters+1),hh),...
        X(C==(n.clusters+1),ii),...
        '.', 'color', colours{n.clusters+1},'markersize',marker_size);
      
    % run through clusters (backwards)
      for cc = n.clusters:-1:1
        % plot points
          plot(...
            X(C==cc,hh), ...
            X(C==cc,ii), ...
            '.','color',colours{cc},'markersize',marker_size);
        % plot mean
          plot( ...
            data.EM.M(hh,cc), ...
            data.EM.M(ii,cc), ...
            'ko','linewidth',8 );    
        % plot contour        
          switch L(stdmax)
            case 1
              stdmax_cc = stdmax;
            otherwise
              stdmax_cc = stdmax(cc);
          end            
          for jj=stdmax_cc:-1:1
            try
            plot_std_ellipse(...
              data.EM.M([hh ii],cc), ...
              jj^2 * data.EM.V([hh ii],[hh ii],cc),...
              colours{cc} * 1/jj + (1-1/jj)*[1 1 1]);
            catch
            end
          end
      end
      
    % graph limits
      try
        if zoomlevel == 0        
          xlim([xmins(hh) xmaxs(hh)]);
          ylim([xmins(ii) xmaxs(ii)]);
        else
          xmin = mean(X(:,hh)) - zoomlevel*std(X(:,hh));
          xmin = max([xmin min(X(:,hh))]);          
          xmax = mean(X(:,hh)) + zoomlevel*std(X(:,hh));
          xmax = min([xmax max(X(:,hh))]);
          
          ymin = mean(X(:,ii)) - zoomlevel*std(X(:,ii));
          ymin = max([ymin min(X(:,ii))]);          
          ymax = mean(X(:,ii)) + zoomlevel*std(X(:,ii));
          ymax = min([ymax max(X(:,ii))]);

          xlim([xmin xmax]);
          ylim([ymin ymax]);
        end
      catch
      end
    
    % labels
      if ii==n.dims
        xlabel(fixfortex(data.EM.features{hh}),'fontweight','bold','fontsize',14);
      else
        set(gca,'xticklabel',{});
      end
      
      if hh==1
        ylabel(fixfortex(data.EM.features{ii}),'fontweight','bold','fontsize',14);
      else
        set(gca,'yticklabel',{});
      end
    
    
  end
end
  

% reposition axes

for hh=1:(n.dims-1)
  for ii=(hh+1):n.dims
        
    xn = hh;
    yn = n.dims-(ii-1);
    set(sp(hh,ii),'position',...
      [ spsize.start.x + (spsize.width.x + spsize.gap.x)*(xn-1), ...
        spsize.start.y + (spsize.width.y + spsize.gap.y)*(yn-1), ...
        spsize.width.x, ...
        spsize.width.y ]);
    
  end
end



%% statistics
% =============

n.rows = 5 + show_isi;
n.cols = n.clusters+1;
subplot_pos = @(row,col) (row-1)*n.cols + col;

%close(n.fig2);
figure(n.fig2);
%set(gcf,'position',[1681 5 839 971]);
clf;
try set(gcf,'name',data(1).metadata.filename(1:(end-4))); catch end

% psth
% -----

  row = 1;
  for cc=1:n.cols
    subplot(n.rows, n.cols, subplot_pos(row,cc));
    tt = data.cluster(cc).psth.tt;    
    if max(tt)>1, tt=tt/1000; end
    count = data.cluster(cc).psth.count;
    bar(tt, count, ...
      'facecolor', colours{cc});
    xlim([0 (max(tt) + (tt(2)-tt(1))/2)]);
    ylim([0 0.01+1.05*max(count)])
  end
  
  subplot(n.rows, n.cols, subplot_pos(row,1) );
    ylabel('psth','fontsize',14,'fontweight','bold');

    
% autocorrelograms
% ------------------

  row = 2;
  for cc=1:n.cols
    subplot(n.rows, n.cols, subplot_pos(row,cc));
    try
      tt    = data.cluster(cc).autocorrelogram.tt;
      count = data.cluster(cc).autocorrelogram.count;
      bar(tt, count, ...
        'facecolor', colours{cc}, 'edgecolor',colours{cc});
      xlim([tt(1) - (tt(2)-tt(1))/2, 25]);
      ylim([0 0.01+1.05*max(count)]);
      yts = get(gca,'ytick');
      yts = yts(mod(yts,1)==0);
      set(gca,'ytick',yts);
    catch
    end
  end

  subplot(n.rows, n.cols, subplot_pos(row,1) );
    ylabel('acg','fontsize',14,'fontweight','bold');

% interspike intervals
% ----------------------
  if show_isi
    row = 3;
    for cc=1:n.cols
      subplot(n.rows, n.cols, subplot_pos(row,cc));
      try
        tt = data.cluster(cc).interspike_interval.tt;
        count = data.cluster(cc).interspike_interval.count;
        bar(tt, count, ...
          'facecolor', colours{cc},'edgecolor',colours{cc});
        xlim([tt(1) - (tt(2)-tt(1))/2, 25]);
        ylim([0 0.01+1.05*max(count)]);
        yts = get(gca,'ytick');
        yts = yts(mod(yts,1)==0);
        set(gca,'ytick',yts);
      catch
      end
    end
    
    subplot(n.rows, n.cols, subplot_pos(row,1) );
      ylabel('isi','fontsize',14,'fontweight','bold');
  end
  
% shapes -- original
% -------------------

  % prepare
    row = 3+show_isi;
    shape_length = size(data.spikes.shapes,1);
      
    for cc=1:n.cols
      subplot(n.rows, n.cols, subplot_pos(row,cc));
      cla; hold on;
      set(gca,...
        'xlimmode','manual','ylimmode','manual',...
        'xlim',[0 shape_length] + [-5 5], 'ylim',maxall(data.spikes.shapes)*[-1 1],...
        'xtick',[],'ytick',[]);
    end
    subplot(n.rows, n.cols, subplot_pos(row,1));
      ylabel('spike\newlineshapes','fontsize',14,'fontweight','bold');
      
  % plot shapes
    for cc=1:n.cols
      subplot(n.rows, n.cols, subplot_pos(row,cc));
      [tt sh] = get_shape_plot_data(data.cluster(cc).spikes.shapes);
      plot(tt, sh, 'color', colours{cc});
      
    % plot mean shape
      meanshape = mean(data.cluster(cc).spikes.shapes,2);
      plot(1:shape_length, meanshape,'color','k','linewidth',2);
      hold off;
    end        
    
  % spike counts
    if SKIP_ALIGNMENT
      for cc=1:n.cols
        subplot(n.rows, n.cols, subplot_pos(row,cc));
        xlabel([num2str(data.cluster(cc).nspikes) ' spikes'],'fontsize',14,'fontweight','bold');    
      end  
    end

    
    
% shapes -- aligned
% -------------------

if ~SKIP_ALIGNMENT
  try
    % prepare
      row = 4+show_isi;
      for cc=1:n.cols
        subplot(n.rows, n.cols, subplot_pos(row,cc));
        cla; hold on;
        set(gca,...
          'xlimmode','manual','ylimmode','manual',...
          'xlim',[0 shape_length+11], 'ylim',maxall(data.spikes.shapes)*[-1 1],...
          'xtick',[],'ytick',[]);
      end
      subplot(n.rows, n.cols, subplot_pos(row,1));
        ylabel('aligned\newlineshapes','fontsize',14,'fontweight','bold');

    % spike counts
      for cc=1:n.cols
        subplot(n.rows, n.cols, subplot_pos(row,cc));
        xlabel([num2str(data.cluster(cc).nspikes) ' spikes'],'fontsize',14,'fontweight','bold');    
      end  

    % plot shapes
      for cc=1:n.cols
        subplot(n.rows, n.cols, subplot_pos(row,cc));
          try
            [tt sh] = get_aligned_shape_plot_data(data.cluster(cc).spikes.shapes_aligned);
          catch
            try
              data.cluster(cc).spikes.shapes_aligned = getfield(align_shapes(data.cluster(cc).spikes.shapes),'aligned'); %#ok<GFLD>
              [tt sh] = get_aligned_shape_plot_data(data.cluster(cc).spikes.shapes_aligned);
            catch
            [tt sh] = get_shape_plot_data(data.cluster(cc).spikes.shapes);
            end
          end
        plot(tt, sh, 'color', colours{cc});
        set(gca,'xlim',[min(tt) max(tt)]);

      % plot mean shape
        try
          meanshape = nanmean(data.cluster(cc).spikes.shapes_aligned,2);
          plot(8:(13+shape_length), meanshape(8:(13+shape_length)),'color','k','linewidth',2);
        catch
        end
        hold off;
      end        
  catch
  end
end


% histogram of spikes over repeat #
% ----------------------------------

  row = 5+show_isi;
  subplot(n.rows,1,row);
  hold on;
  
  if show_excision_adjusted_spike_counts
    scale_factor = get_excision_adjusted_spike_counts(data);
      for cc=1:(n.clusters+1)
        yy = data.cluster(cc).spikes_per_repeat.count .* scale_factor;
        yy( yy == 0) = nan;
        plot( ...
          data.cluster(cc).spikes_per_repeat.repeat_id, ...
          yy, ...
          's--', 'color', colours{cc}*0.4 + 0.6*[1 1 1],'linewidth',2);
      end
  end

  for cc=1:(n.clusters+1)
    yy = data.cluster(cc).spikes_per_repeat.count;
    yy( yy==0 ) = nan;
    plot( ...
      data.cluster(cc).spikes_per_repeat.repeat_id, ...
      yy, ...
      's-', 'color', colours{cc},'linewidth',2);
  end
    
  xlabel('repeat #','fontsize',13,'fontweight','bold');    
  ylabel('# spikes','fontsize',13,'fontweight','bold');    
    xts = get(gca,'xtick');
    xts = xts(mod(xts,1)==0);
    set(gca,'xtick',xts);
  yl = ylim; ylim([0 yl(2)]);
    
  
% titles
% --------

  row = 1;
  for cc=1:n.cols
    subplot(n.rows, n.cols, subplot_pos(row,cc));
    if cc <= n.clusters
      title(['cluster ' num2str(cc)],'fontsize',16,'fontweight','bold');
    else
      title('unclassified','fontsize',16,'fontweight','bold');
    end
  end
    
end




%% ===============================================================
function plot_std_ellipse(M,V,col)

  [ev d] = eig(V);
  d = diag(d);

  ra = sqrt(d(2));
  rb = sqrt(d(1));
  phi = atan(ev(2,2)/ev(1,2));
  x0 = M(1);
  y0 = M(2);
  h=ellipse(ra,rb,phi,x0,y0,col);

end


% ---
function [tt sh] = get_shape_plot_data(shapes)
  shapes1 = shapes;
  shapes2 = flipud(shapes);
  shape_length = size(shapes,1);
  
  n.spikes = size(shapes,2);
  switch mod(n.spikes,2)
    case 0
      tokeep  = repmat(([true false]),shape_length,n.spikes/2);
      tt      = repmat( ([1:shape_length shape_length:-1:1])',n.spikes/2, 1 );
    case 1
      tokeep = [repmat(([true false]),shape_length,floor(n.spikes/2)) true(shape_length,1)];
      tt = [ repmat( ([1:shape_length shape_length:-1:1])', floor(n.spikes/2), 1 ); (1:shape_length)' ];
  end
  
  shapes1 = shapes1 .* tokeep;
  shapes2 = shapes2 .* (~tokeep);
  sh = shapes1 + shapes2;
  sh = sh(:);
end


% ---
function [tt shapes] = get_aligned_shape_plot_data(shapes)
  
  if isempty(shapes)
    tt = [];
    shapes = [];
    return;
  end
  
  shape_length = size(shapes,1);
  
  for ii=1:24
    shapes(ii, isnan(shapes(ii,:))) = 0;
  end
  
  shapes = [shapes; flipud(shapes)];
  tt     = repmat(([1:shape_length shape_length:-1:1])', 1, size(shapes,2));

  shapes = shapes(:);
  tt = tt(:);
  tt = tt(~isnan(shapes));
  shapes = shapes(~isnan(shapes));

end


% ---
function scale_factor = get_excision_adjusted_spike_counts(data)
%   repeat_ids          = [data.sweeps([data.excisions.boundaries.sweeps]).repeat_id];
%   excision_durations  = data.excisions.durations.dt;
%   total_excision_durations = zeros(1,data.metadata.n.repeats);
%   for ii=1:data.metadata.n.repeats
%     total_excision_durations(ii) = sum(excision_durations(repeat_ids==ii));
%   end
%   total_repeat_duration = data.metadata.maxt_dt * data.metadata.n.sets;
%   scale_factor = total_repeat_duration ./ (total_repeat_duration - total_excision_durations);
  % determine scale factor
    repeat_ids                = [data.sweeps([data.excisions.boundaries.sweeps]).repeat_id];
    excision_durations        = data.excisions.durations.dt;
    dur.excised   = zeros(1,data.metadata.n.repeats);
    dur.total     = zeros(1,data.metadata.n.repeats);
    for ii=1:data.metadata.n.repeats,
      dur.excised(ii)   = sum(excision_durations(repeat_ids==ii));
      dur.total(ii)     = data.metadata.maxt_dt * sum([data.sweeps.repeat_id]==ii);
    end
    dur.remaining = dur.total - dur.excised;
    scale_factor = 1 ./ dur.remaining;
    scale_factor = scale_factor / min(scale_factor);
end  