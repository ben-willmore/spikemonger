function allCEs = find_candidate_events(dirs, sweep)

% sample rate
dt = 0.040959999071638; % ms
fs = 1000/dt;           % Hz

% get sweep_params
ts = sweep.by_type.sweep_params(1).timestamp;
%swp = get_sweep_file(dirs, ts, 'sweep_params');

% get candidate events
fsigs = sweep.by_type.filtered_signal;
n.channels = L(fsigs);
allCEs = struct;
[allCEs.time_smp allCEs.trigger allCEs.time_ms] = IA([]);

for ii=1:n.channels
  
  % find trigger events on each channel
  sig = get_sweep_file(dirs, fsigs(ii));
  fsigs(ii).signal = sig;
  CEs = get_candidate_events_from_signal(sig);
%  CEs_pos = get_candidate_events_from_signal(sig);
%  CEs_neg = get_candidate_events_from_signal(-sig);
%  CEs = struct;
%  CEs.time_ms  = [CEs_pos.time_ms  CEs_neg.time_ms];
%  CEs.time_smp = [CEs_pos.time_smp CEs_neg.time_smp];
  CEs.trigger = ones(1,L(CEs.time_smp)) * ii;
  
  % put together into a single structure
  allCEs.time_smp = [allCEs.time_smp; CEs.time_smp'];
  allCEs.time_ms  = [allCEs.time_ms; CEs.time_ms'];
  allCEs.trigger  = [allCEs.trigger; CEs.trigger'];
  
end

% remove duplicates
[vals idx1 idx2] = unique(allCEs.time_smp);
allCEs.time_smp = allCEs.time_smp(idx1);
allCEs.time_ms = allCEs.time_ms(idx1);
allCEs.trigger = allCEs.trigger(idx1);

% fix fsigs, if required
fsigl = Lincell({fsigs.signal});
if L(unique(fsigl))>1
  if max(fsigl)-min(fsigl)<2
    correct_fsigl = min(fsigl);
    for ii=1:L(fsigs)
      fsigs(ii).signal = fsigs(ii).signal(1:correct_fsigl);
    end
  else
    warning('parse:error','signal lengths are too different from one another. must fix');
    keyboard;
  end
end

% shapes
n.CEs = L(allCEs.time_smp);
s = [fsigs.signal];
allCEs.shape = nan(n.CEs,40,n.channels);
for ii=1:n.CEs
  try
  allCEs.shape(ii,:,:) = s(allCEs.time_smp(ii) + (-14:25),:);
  catch
    keyboard;
  end
end

allCEs.shape = single(allCEs.shape);
