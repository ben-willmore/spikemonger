function CEs = compile_candidate_event_database_for_large_data(dirs,swl)
  % CEs = compile_candidate_event_database(dirs,swl)
  
  MAX_CEs = 200000;
  
  %% calculate timestamps
  % ======================
  
  % timestamps
  tss = {swl.timestamp};
  
  % convert to vecotrs
  tss = datevec(datenum(tss,'yyyymmdd-HHMMSSFFF'));
  
  % subtract the first one
  tss = tss - repmat(tss(1,:),size(tss,1),1);
  
  % put into seconds form
  tss = datevec(datenum(tss));
  tss = tss(:,6) + 60*(tss(:,5) + 60*(tss(:,4) + 24*tss(:,2)));
  
  
  %% create CEs
  % ==============
  
  % first, load all the sweep CEs
  % -------------------------------
  
  n.sweeps = L(swl);
  
  % temporary structure
  cets = cell(1,n.sweeps);
  fprintf_bullet('loading candidate events',2); p=0; t1=clock;
  
  % run through sweeps and put them in the structure
  for ii=1:n.sweeps
    p = print_progress(ii,n.sweeps,p);
    ts = swl(ii).timestamp;
    sweep_start_time = tss(ii);
    cet = get_sweep_file(dirs, ts, 'candidate_events');
    cet.n_ces = L(cet.time_smp);
    cet.timestamps = repmat({ts},cet.n_ces,1);
    cet.time_absolute_s = sweep_start_time + cet.time_ms/1000;
    cets{ii} = cet;
  end
  cets = cell2mat(cets);
  fprintf_timediff(t1);
  
  
  % pick out a random sample
  % ----------------------------
  
  % pick a random sample
  n_ces = sum([cets.n_ces]);
  if n_ces <= MAX_CEs
    tokeep = 1:n_ces;
  else
    tokeep = sort(randsample(n_ces, MAX_CEs));
  end
  
  % for each sweep, pick a random sample
  count_tokeep = 0;
  fields = setdiff(fieldnames(cets),'n_ces');
  for ii=1:L(cets)
    % which to keep of these
    idx_min = count_tokeep + 1;
    idx_max = count_tokeep + cets(ii).n_ces;
    tokeep_this = tokeep((tokeep>=idx_min) & (tokeep<=idx_max)) - count_tokeep;
    % pull out these ones from each field
    for ff=1:L(fields)
      fi = fields{ff};
      cets(ii).(fi) = cets(ii).(fi)(tokeep_this);
    end
    % update the number of CEs
    cets(ii).original_n_ces = cets(ii).n_ces;
    cets(ii).n_ces = L(tokeep_this);
    count_tokeep = idx_max;
  end
  
  
  % make them a new structure
  % ---------------------------
  
  % initialise a structure to put them in
  n.ces = sum([cets.n_ces]);
  CEs = struct;
  [CEs.time_smp CEs.trigger CEs.time_ms CEs.time_absolute_s] = IA(nan(n.ces,1));
  CEs.timestamps = cell(n.ces, 1);
  
  % transfer
  count_ce = 0;
  for ii=1:n.sweeps
    % indices
    jjs = count_ce + (1:cets(ii).n_ces);
    % transfer
    CEs.time_smp(jjs,:) = cets(ii).time_smp;
    CEs.time_ms(jjs,:) = cets(ii).time_ms;
    CEs.time_absolute_s(jjs,:) = cets(ii).time_absolute_s;
    CEs.trigger(jjs,:) = cets(ii).trigger;
    CEs.timestamps(jjs,:) = cets(ii).timestamps;
    % update indices
    count_ce = count_ce + cets(ii).n_ces;
  end
    
  % import shapes
  % ----------------
  
  % get example shape size
  sh = get_sweep_file(dirs, ts, 'shapes');
  % create a container
  CEs.shape = nan(n.ces, size(sh,2), size(sh,3), 'single');
  % run through sweeps
  fprintf_bullet('loading shapes',2); p=0; t1=clock;
  count_ce = 0; count_tokeep = 0;
  for ii=1:n.sweeps
    p = print_progress(ii,n.sweeps,p);
    % load sweep shapes
    ts = swl(ii).timestamp;
    sh = get_sweep_file(dirs, ts, 'shapes');
    % which to keep of these
    idx_min = count_tokeep + 1;
    idx_max = count_tokeep + cets(ii).original_n_ces;
    tokeep_this = tokeep((tokeep>=idx_min) & (tokeep<=idx_max)) - count_tokeep;
    % indices    
    jjs = count_ce + (1:cets(ii).n_ces);
    % transfer
    CEs.shape(jjs,:,:) = sh(tokeep_this,:,:);
    % update indices
    count_tokeep = count_tokeep + cets(ii).original_n_ces;
    count_ce = count_ce + cets(ii).n_ces;
  end
  fprintf_timediff(t1);
    
    