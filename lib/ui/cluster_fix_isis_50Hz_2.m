function [C n_harmonics_to_delete] = cluster_fix_isis_50Hz_2(C,id,dirs,cols,forced_n_harmonics)
  % C = cluster_fix_isis_50Hz(C,id)

%% parse input
% =============

if nargin<4
  col = 'b';
else
  col = cols(id,:);
end

force = false;
if nargin==5  
  force = true;
end

  
%% parse C
% ==========

data = C.data(id);
isis = C.isis(id);

% for sweep count
ts = get_timestamps_from_swl(get_event_file(dirs,'sweep_list'));
ts = ts.str;
sweep_count2 = nan(1,L(ts));


%% get long view of harmonics
% =============================

maxt_ms = L(C.psth(id).tt_10ms_bins) * 10;
max_n_harmonics = floor(maxt_ms/20);
harmonics_to_show = min(max_n_harmonics,20);
maxt_isi = max_n_harmonics * 20 + 5;
maxt_to_show = harmonics_to_show * 20 + 5;

isi0 = C.isis(id);
[acg1 isi1] = calculate_acg(C.data(id),maxt_isi);


%% plot
% ========

if ~force
  
% prepare figure
p.fig = figure; 
set_fig_size(1000,600);
put_fig_in_top_right;

% plot
col = cols(id,:);
clf; 
ax(2,1,1,'gapx',0.1);
hold on;
bar(isi1.tc, isi1.count,'facecolor',col,'barwidth',1,'linestyle','none');
xlim([0 maxt_to_show]);

% peaks
peakpos = 200:200:(200*harmonics_to_show);
for ii=1:L(peakpos);
  x = 20*ii;
  y = max(isi1.count(peakpos(ii)+(-2:2)));
  text(x,y,n2s(ii),'verticalalignment','bottom','horizontalalignment','center');
end

% aesthetics
ylabel12bf('count');
xlabel12bf('ISI time interval (ms)');
xt = [0:20:80 100:100:max(isi1.tc)];
set(gca,'xtick',xt);

end

%% request how many
% ====================

if ~force
  
  fprintf('\n');
  fprintf([...
    'How many harmonics to delete?\n\n' ...
    '  [1-20]:  1-20\n'...
    '  [99]:    all\n'...
    '  [0]:     cancel\n\n']);
  n_harmonics_to_delete = demandnumberinput('           >>>  ',[0:20 99]);

  if n_harmonics_to_delete==0
    return;
  end

% if forced
else
  n_harmonics_to_delete = forced_n_harmonics;
end


if n_harmonics_to_delete==99
  n_harmonics_to_delete = max_n_harmonics;
end
    


%% current distribution around (20*n +/- 0.5)ms
% =============================================

dist = struct;
[min_tc_idx max_tc_idx tc_idx i] = IA(cell(1,n_harmonics_to_delete));
for hh=1:n_harmonics_to_delete

  % height at boundaries
  min_t(hh) = 20*hh - 0.5;
  max_t(hh) = 20*hh + 0.5;
  try
  min_tc_idx{hh} = head(find(isi1.tc >= min_t(hh)));
  catch
    keyboard;
  end
  max_tc_idx{hh} = tail(find(isi1.tc <= max_t(hh)));
  min_count(hh) = mean(round(isi1.count(min_tc_idx{hh} + (-2:0)))); % average for stability
  max_count(hh) = mean(round(isi1.count(max_tc_idx{hh} + (0:2)))); % average for stability

  % imposed distribution
  tc_idx{hh} = min_tc_idx{hh}:max_tc_idx{hh};
  i{hh} = mean([min_count(hh),max_count(hh)]) * ones(size(tc_idx{hh}));

  dist(hh).original = isi1.count(tc_idx{hh});
  dist(hh).imposed = i{hh};
  dist(hh).probability_of_keeping = min(dist(hh).imposed ./ dist(hh).original,1);
  dist(hh).tc = isi1.tc(tc_idx{hh});
  dist(hh).tt = isi1.tt(min_tc_idx{hh}:(max_tc_idx{hh}+1));
end


%% perform adjustment
% =====================

% run through sets
for ss=1:L(data.set)
  
  % run through repeats
  for rr=1:L(data.set(ss).repeats)
    
    % what isis are problematic
    spt = data.set(ss).repeats(rr).t;
    if L(spt)<=1, continue; end
    tokeep = true(1,L(spt));
    isi = diff(spt);
    
    % which group do they belong to
    [harmonic_gp,problem_isi_idx] = ...
      find(...
      (repmat(isi,n_harmonics_to_delete,1) >= repmat(min_t',1,L(isi))) ...
      & (repmat(isi,n_harmonics_to_delete,1) <= repmat(max_t',1,L(isi))));
    
    n_problem_isis = L(problem_isi_idx);
    
    % run through each problem_isi
    for ii=1:n_problem_isis
      isi_ii = isi(problem_isi_idx(ii));
      hgp_ii = harmonic_gp(ii);
      % what bin is the isi in
      h = histc_nolast(isi_ii,dist(hgp_ii).tt);
      % what is the probability of keeping it
      prob = dist(hgp_ii).probability_of_keeping(h==1);
      % keep it?
      if (rand > prob)
        tokeep(problem_isi_idx(ii)) = false;
      end
    end
    
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


% calculate new acgs, etc
[acg2 isi2] = calculate_acg(data,maxt_isi);

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


%% plot
% ========

if ~force
  
  % plot
  ax(2,1,2,'gapx',0.1);
  hold on;
  bar(isi2.tc, isi2.count,'facecolor',col,'barwidth',1,'linestyle','none');
  xlim([0 maxt_to_show]);
  
  ylabel12bf('count');
  xlabel12bf('ISI time interval (ms)');
  
  xt = [0:20:80 100:100:max(isi2.tc)];
  set(gca,'xtick',xt);

  % plot psths
  p2 = plot_clusters_psth_all([C.psth(id) psth2],[C.sve(id) sve2],[cols(id,:); 0 0 0],1:2);
  
  % ask if this is ok
  to_save = demandinput(['\n\nIs this ok?\n' ...
    '        [y/n]   >>>  '], {'yes','no','y','n','Y','N','No','NO','YES','Yes'});
  
  % close figures
  try
    close(p.fig);
  catch, end
  try
    close(p2.fig);
  catch, end
  
  if ~ismember(to_save,{'yes','y','Y','Yes','YES'})
    n_harmonics_to_delete = 0;
    return;
  end
  
end


%% finish
% ========


% new acgs/isis
[acgs2 isis2] = calculate_acg(data);


% finish
C.psth(id) = psth2;
C.acgs(id) = acgs2;
C.isis(id) = isis2;
C.sve(id) = sve2;
C.data(id) = data;
C.sweep_count{id} = sweep_count2;

