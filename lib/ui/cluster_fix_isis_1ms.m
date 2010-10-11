function C = cluster_fix_isis_1ms(C,id,dirs,cols,varargin)
  % C = cluster_fix_isis_1ms(C,id)

%% parse input
% =============

if nargin<4
  col = 'b';
else
  col = cols(id,:);
end

force = false;
if nargin>=5
  if ismember('skip_plot',varargin) | ismember('force',varargin)
    force = true;
  end
end
  
%% parse C
% ==========

data = C.data(id);
isis = C.isis(id);

% for sweep count
ts = get_timestamps_from_swl(get_event_file(dirs,'sweep_list'));
ts = ts.str;
sweep_count2 = nan(1,L(ts));

%% current distribution from 1ms downwards
% ==========================================

% height at 1ms
max_t = 1;
max_tc_idx = tail(find(isis.tc < max_t));
max_count = mean(round(isis.count(max_tc_idx + (-1:1)))); % average for stability

% imposed distribution
tc_idx = 1:max_tc_idx;
i = tc_idx.^2;
i = i * max_count / max(i);

dist = struct;
dist.original = isis.count(tc_idx);
dist.imposed = i;
dist.probability_of_keeping = min(dist.imposed ./ dist.original,1);
dist.tc = isis.tc(tc_idx);
dist.tt = isis.tt(1:(max_tc_idx+1));


%% perform adjustment
% =====================

% run through sets
for ss=1:L(data.set)
  
  % run through repeats
  for rr=1:L(data.set(ss).repeats)
    
    % what isis are problematic
    data.set(ss).repeats(rr).t = sort(data.set(ss).repeats(rr).t);
    spt = data.set(ss).repeats(rr).t;
    tokeep = true(1,L(spt));
    isi = diff(spt);
    problem_isi_idx = find(isi<1);
    n_problem_isis = L(problem_isi_idx);
    
    % run through each problem_isi
    for ii=1:n_problem_isis
      % what group is the isi in
      h = histc_nolast(isi(problem_isi_idx(ii)),dist.tt);
      % what is the probability of keeping it
      p = dist.probability_of_keeping(h==1);
      % keep it?
      if (rand > p)
        tokeep(problem_isi_idx(ii)) = false;
      end
    end
    
    %disp([L(spt) n_problem_isis mean(tokeep)]);
    
    % save these back to the data structure
    spt = spt(tokeep);
    data.set(ss).repeats(rr).t = spt;
    data.set(ss).repeats(rr).repeat_id = repmat(rr,1,L(spt));
    
    % add to new sweep count
    sweep_idx = ismember(ts,data.set(ss).repeats(rr).timestamp);
    sweep_count2(sweep_idx) = L(spt);
  end
  
  % compile spikes
  data.set(ss).spikes.t = [data.set(ss).repeats.t];
  data.set(ss).spikes.repeat_id = [data.set(ss).repeats.repeat_id];
  
end


% new sve
sve2 = sahani_variance_explainable_2(data);

% new psth
psth2 = struct;
dhs = [2 5 10 25];
maxt = ceil(max([data.set.length_signal_ms]));
spike_times = reach(data.set,'spikes.t');
for dd=1:L(dhs)
  dh = dhs(dd);
  fn_psth = ['count_' n2s(dh) 'ms_bins'];
  fn_tt = ['tt_' n2s(dh) 'ms_bins'];
  tt = 0:dh:maxt;
  psth2.(fn_psth) = histc_nolast(spike_times,tt);
  psth2.(fn_tt)   = midpoints(tt);
end

% new acgs/isis
[acgs2 isis2] = calculate_acg(data);


% if force finish
if force
  C.psth(id) = psth2;
  C.acgs(id) = acgs2;
  C.isis(id) = isis2;
  C.sve(id) = sve2;
  C.data(id) = data;
  C.sweep_count{id} = sweep_count2;
  return;
end


%% plot
% =======


p = struct;
p.fig = figure(100); clf;
put_fig_in_top_right;

% ISI before
% --------

% plot ISI
p.ax(1) = ax(2,2,1,1,'gapy',0.3); hold on;
p.bar = bar(isis.tc, isis.count, 'barwidth', 1, 'facecolor',col, 'linestyle', 'none');

% aesthetics
set(gca,'xtick',[0:2 4:2:30],'tickDir','out');
set(gca,'xticklabel',{},'yticklabel',{},'ytick',[]);
set(gca,'tickDir','out');
title14bf('ISI before');
xl = xlim;
ylim([0 max(max(isis.count)*1.12,1)]);
yl = ylim;

% percent
pc_less_than_1ms = round(sum(isis.count(tc_idx)) / sum(isis.count) * 1000)/10;
str = ['< 1ms  =  ' n2s(pc_less_than_1ms) ' %'];
text(0.2,max(max(isis.count)*1.1,0.95), str,'fontweight','bold','verticalalignment','top');
  

% ISI after
% --------

% plot ISI
p.ax(2) = ax(2,2,2,1,'gapy',0.3); hold on;
p.bar = bar(isis2.tc, isis2.count, 'barwidth', 1, 'facecolor',col, 'linestyle', 'none');

% aesthetics
set(gca,'yticklabel',{},'ytick',[]);
set(gca,'xtick',[0:2 4:2:30],'tickDir','out');
xlabel12bf('time (ms)');
ylabel12bf('count');
title14bf('ISI after');

% percent
pc_less_than_1ms = round(sum(isis2.count(tc_idx)) / sum(isis.count) * 1000)/10;
str = ['< 1ms  =  ' n2s(pc_less_than_1ms) ' %'];
text(0.2,max(max(isis.count)*1.1,0.95), str,'fontweight','bold','verticalalignment','top');

xlim(xl); ylim(yl);


%% PSTH before
% -------------

p.ax(3) = ax(2,2,1,2,'gapy',0.3); hold on;

tt = C.psth(id).(['tt_5ms_bins']);
count =  C.psth(id).(['count_5ms_bins']);
p.bar = bar( tt, count, 'facecolor','k', 'linestyle','none','barwidth',1);

% aesthetics
dt = (tt(2)-tt(1));
xlim([tt(1)-dt/2 tt(end)+dt/2 ]);
noticks;

% title
title12bf('PSTH before');

% sahani variance explained
sig = C.sve(id).percentage_signal.at_5ms;
if isnan(sig)
  try
    sig = C.sve(id).pooled.percentage_signal.at_5ms;
  catch
  end
end
sig = round(sig*10)/10;
sig = ['SP = ' n2s(sig) '%'];
xl = xlim; yl = ylim;
p.sve = text( max(tt)*0.02, max(count)*1.1, sig, ...
  'fontweight','bold', 'verticalalignment','top');
ylim([0 max(max(count)*1.12,1)]);


%% PSTH after
% -------------

p.ax(3) = ax(2,2,2,2,'gapy',0.3); hold on;

tt = psth2.(['tt_5ms_bins']);
count =  psth2.(['count_5ms_bins']);
p.bar = bar( tt, count, 'facecolor','k', 'linestyle','none','barwidth',1);

% aesthetics
dt = (tt(2)-tt(1));
xlim([tt(1)-dt/2 tt(end)+dt/2 ]);
noticks;

% title
title12bf('PSTH after');

% sahani variance explained
sig = sve2.percentage_signal.at_5ms;
if isnan(sig)
  try
    sig = sve2.pooled.percentage_signal.at_5ms;
  catch
  end
end
sig = round(sig*10)/10;
sig = ['SP = ' n2s(sig) '%'];
xl = xlim; yl = ylim;
p.sve = text( max(tt)*0.02, max(count)*1.1, sig, ...
  'fontweight','bold', 'verticalalignment','top');
ylim([0 max(max(count)*1.12,1)]);

%p.p = plot(isis.tc(t),i,'r','linewidth',2);

%% ask if this is acceptable
% =============================

fprintf('\n');
to_continue = demandinput('Do you like?   [y/n]   >>> ',{'y','n'});

% close the figure
try
  close(p.fig);
catch
end

% quit if requested
if isequal(to_continue,'n');
  return;
end


%% perform changes
% ==================

% save into C
C.psth(id) = psth2;
C.acgs(id) = acgs2;
C.isis(id) = isis2;
C.sve(id) = sve2;
C.data(id) = data;
C.sweep_count{id} = sweep_count2;
