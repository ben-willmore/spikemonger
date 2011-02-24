function A3_analyse_clusters(dirs, cluster_type, varargin)
  % A3_analyse_clusters(dirs, cluster_type)
  % A3_analyse_clusters(dirs, cluster_type, swl)

%% parse input
% ==================

% default cluster
default_cluster_type = 'clusters_pentatrodes';
try
  if nargin==1
    cluster_type = default_cluster_type;
  end
catch
  cluster_type = default_cluster_type;
end

% params
setpath;
dirs = fix_dirs_struct(dirs);


%% get data
% ==========

t1 = clock;
fprintf_subtitle(['(3) calculating clustering statistics  (' cluster_type ')']);

% skip if already done
if does_log_exist(dirs,['A3.' cluster_type '.statistics.calculated']);
  fprintf_bullet('already done.\n');
  return;
end

% load
fprintf_bullet('loading cluster data...');
swl = get_event_file(dirs,'sweep_list');
ts = get_timestamps_from_swl(swl);
sweep_params = get_event_file(dirs,'sweep_params');

switch cluster_type
  case 'clusters_full'
    CEs = get_event_file(dirs,'candidate_events_full');
    fsp = get_event_file(dirs,'feature_space_full');
  case 'clusters_pentatrodes'
    CEs = get_event_file(dirs,'candidate_events_pentatrodes');
    fsp = get_event_file(dirs,'feature_space_pentatrodes');
  case 'clusters_full_no_time'
    CEs = get_event_file(dirs,'candidate_events_full');
    fsp = get_event_file(dirs,'feature_space_full');
    fsp = fsp(:,1:(end-1));
end

% load cluster
c = get_event_file(dirs,cluster_type);
n.c = c.n_clusters;

% prepare target dir
dirs.cluster = [dirs.root cluster_type '/'];
mkdir_nowarning(dirs.cluster);
fprintf_timediff(t1);


%% are we in a memory workaround
% ================================
  
  % get the parameters
  s = size(CEs.shape);
  n.ch = s(3);
  n.sh_per_c = 1000;
  n.sh_total = n.sh_per_c * n.c;

  % which examples to use
  eg_idxs = cell(n.c,1);
  for cc=1:n.c
    eg_idxs{cc} = find(c.C==cc);
    eg_idxs{cc} = eg_idxs{cc}( head(randperm(L(eg_idxs{cc})), min(L(eg_idxs{cc}),n.sh_per_c) ) );
  end
  n.eg_shapes = sum(Lincell(eg_idxs));

  % pick out examples
  sh = CEs.shape(cell2mat(eg_idxs),:,:);





%% divide up into sets
% ======================

% retrieve sweep params
n.sweeps = L(swl);
sp = cell(1,n.sweeps);
sweep_params_timestamps = {sweep_params.timestamp};
for ii=1:n.sweeps
  sp{ii} = sweep_params(find(ismember(sweep_params_timestamps, swl(ii).timestamp),1));
end
sp = cell2mat(sp)';

% add length of signal to sweep params
for ii=1:L(sp)
  sp(ii).all.names = [sp(ii).all.names; 'length_signal_ms'];
  sp(ii).all.values = [sp(ii).all.values; round(sp(ii).length_signal_ms)];
end

% which set do they belong to
[usp junk set_ids] = unique(reach(sp,'all.values')','rows');
for ii=1:L(sp)
  sp(ii).set_id = set_ids(ii);
end

% set list
st = struct;
for ii=1:L(usp)
  st(ii).sweeps = sp(set_ids == ii);
  st(ii).n_sweeps = L(st(ii).sweeps);
  st(ii).timestamps = {st(ii).sweeps.timestamp}';
end
n.set = L(st);


%% some parameters
% ===================

% histograms
maxt = ceil(max([sp.length_signal_ms]));
dhs = [2 5 10 25];


%% make events
% ================

p = 0; t1 = clock;
fprintf_bullet('calculating cluster statistics');
for cc=1:n.c
  p = print_progress(cc,n.c,p);
  
  % find events
  tok = c.C==cc;
  n.events = sum(tok);

  
  % parse CE
  % ----------  
  
  % time of each event within a sweep, in samples
  event.time_smp = CEs.time_smp(tok);
  save_cluster_file(dirs,cc,event.time_smp,'event_time_smp');

  % time of each event within a sweep, in ms
  event.time_ms = CEs.time_ms(tok);
  save_cluster_file(dirs,cc,event.time_ms,'event_time_ms');

  % time of each event, since the start of the recording
  event.time_absolute_s = CEs.time_absolute_s(tok);
  save_cluster_file(dirs,cc,event.time_absolute_s,'event_time_absolute_s');

  % event shape across the different channels
  idx_is = droptail(cumsum([0; Lincell(eg_idxs)])) + 1;
  idx_fs = drophead(cumsum([0; Lincell(eg_idxs)]));
  event.shape = sh(idx_is(cc):idx_fs(cc),:,:);
  save_cluster_file(dirs,cc,event.shape,'event_shape');

  % sweep timestamp
  event.timestamps = CEs.timestamps(tok,:);
  save_cluster_file(dirs,cc,event.timestamps,'event_timestamps');
  
  % event trigger
  event.trigger = CEs.trigger(tok);
  save_cluster_file(dirs,cc,event.trigger,'event_trigger');
  
  % sweep id and set id
  [junk event.sweep_id] = ismember(event.timestamps, {sp.timestamp}');
  event.set_id = [sp(event.sweep_id).set_id]';
  save_cluster_file(dirs,cc,event.sweep_id,'event_sweep_id');
  save_cluster_file(dirs,cc,event.set_id,'event_set_id');
  
  
  % parse CE by set
  % ------------------
  
  
  % initialise variables
  [ event.by_set.time_smp ...
    event.by_set.time_ms ...
    event.by_set.time_absolute_s ...
    event.by_set.sweep_id ] = IA(cell(n.set,1));
  
  psth_by_set = struct;
  
  % fill them in
  for ss=1:n.set
    stok = (event.set_id==ss);
    event.by_set.time_smp{ss} = event.time_smp(stok);
    event.by_set.time_ms{ss} = event.time_ms(stok);
    event.by_set.time_absolute_s{ss} = event.time_absolute_s(stok);
    event.by_set.timestamps{ss} = event.timestamps(stok);
    event.by_set.sweep_id{ss} = event.sweep_id(stok);
    
    % psth by set
    for dd=1:L(dhs);
      dh = dhs(dd);
      fn_psth = ['count_' n2s(dh) 'ms_bins'];
      fn_tt   = ['tt_' n2s(dh) 'ms_bins'];
      tt = 0:dh:maxt;
      if ~isempty(event.by_set.time_ms{ss})        
        psth.by_set(ss).(fn_psth) = pickall(histc_nolast(event.by_set.time_ms{ss},tt))';
      else
        psth.by_set(ss).(fn_psth) = 0*tt(1:(end-1));
      end
      psth.by_set(ss).(fn_tt) = midpoints(tt);
      psth.by_set(ss).n_sweeps = st(ss).n_sweeps;
    end
  end
  
  % save
  save_cluster_file(dirs,cc,event.by_set.time_smp,'event_time_smp_by_set');
  save_cluster_file(dirs,cc,event.by_set.time_ms,'event_time_ms_by_set');
  save_cluster_file(dirs,cc,event.by_set.time_absolute_s,'event_time_absolute_s_by_set');
  save_cluster_file(dirs,cc,event.by_set.timestamps,'event_timestamps_by_set');
  save_cluster_file(dirs,cc,event.by_set.sweep_id,'event_sweep_id_by_set');
  save_cluster_file(dirs,cc,psth.by_set,'psth_by_set');
  
  
  % feature space representation
  event.fsp = fsp(tok,:);
  save_cluster_file(dirs,cc,event.fsp,'event_fsp');
  
  % psth - all sets
  psth.all_sets = struct;
  for dd=1:L(dhs)
    dh = dhs(dd);
    fn_psth = ['count_' n2s(dh) 'ms_bins'];
    fn_tt = ['tt_' n2s(dh) 'ms_bins'];
    tt = 0:dh:maxt;
    psth.all_sets.(fn_psth) = histc_nolast(event.time_ms,tt)';
    psth.all_sets.(fn_tt)   = midpoints(tt);
  end
  save_cluster_file(dirs,cc,psth.all_sets,'psth_all_sets');

  % ISIs & ACGs  
  % -------------
  
  % preallocate arrays
  h = hist(event.sweep_id, 1:max(event.sweep_id));
  ISI_list = nan(sum(max(h-1,0)),1);
  ACG_list = nan(sum(h.*(h-1)/2),1);  
  
  % fill in ISIs and ACGs sweep by sweep
  c1=0; c2=0;
  for ss=1:n.sweeps
    stok = (event.sweep_id==ss);
    spt = sort(event.time_ms(stok));
    ISIt = diff(spt);
    ACGt = acg(spt);
    ISI_list(c1+(1:L(ISIt))) = ISIt;
    ACG_list(c2+(1:L(ACGt))) = ACGt;
    c1 = c1 + L(ISIt);
    c2 = c2 + L(ACGt);
  end
  
  % aggregate
  tt = 0:0.1:30;
  ISIs = struct;
  ISIs.tt = tt;
  ISIs.tc = midpoints(tt);
  try
    ISIs.count = histc_nolast(ISI_list,tt)';
  catch
    ISIs.count = 0*tt;
  end
  ACGs = struct;
  ACGs.tt = tt;
  ACGs.tc = midpoints(tt);
  try
    ACGs.count = histc_nolast(ACG_list,tt)';
  catch
    ACGs.count = 0*tt;
  end
    
  % save
  save_cluster_file(dirs,cc,ISIs,'ISIs');
  save_cluster_file(dirs,cc,ACGs,'ACGs');
  
  
  % canonical form
  % -----------------
  data = struct;
  data.set = struct;

  for ss=1:n.set
    % fill in repeats
    for ww=1:st(ss).n_sweeps
      stok = ismember(event.by_set.timestamps{ss}, st(ss).sweeps(ww).timestamp);    
      data.set(ss).spikes = struct;
      data.set(ss).repeats(ww).t = event.by_set.time_ms{ss}(stok)';
      data.set(ss).repeats(ww).repeat_id = repmat(ww,1,sum(stok));
      data.set(ss).repeats(ww).timestamp = st(ss).sweeps(ww).timestamp;
      data.set(ss).stim_params   = rmfield(st(ss).sweeps(1),{'timestamp','length_signal_smp','length_signal_ms','set_id'});
      data.set(ss).length_signal_ms = st(ss).sweeps(1).length_signal_ms;
    end
    
    % fill in spikes
    if st(ss).n_sweeps>0
      data.set(ss).spikes.t = [data.set(ss).repeats.t];
      data.set(ss).spikes.repeat_id = [data.set(ss).repeats.repeat_id];
    else
      data.set(ss).spikes.t = [];
      data.set(ss).spikes.repeat_id = [];
    end    
  end
  data.set = data.set(Lincell({data.set.repeats})>0);
  save_cluster_file(dirs,cc,data,'data');

  
  % sahani variance explainable
  % -----------------------------
  
  % do not run if the individual sets are of different lengths
  if L(unique([data.set.length_signal_ms]))>1
    continue;
  end
  
  % calculate and save
  sve = sahani_variance_explainable_2(data);  
  save_cluster_file(dirs,cc,sve,'sahani_variance_explainable');
  
end
create_log(dirs,['A3.' cluster_type '.statistics.calculated']);
fprintf_timediff(t1);

