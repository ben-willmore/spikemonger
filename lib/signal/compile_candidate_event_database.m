function CEs = compile_candidate_event_database(dirs,swl,varargin)
  % CEs = compile_candidate_event_database(dirs,swl)
  
  % print stuff
  verbose = true;
  if nargin>2
    if ismember('silent',varargin)
      verbose = false;
    end
  end
  
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
% =================


  % first, load all the sweep CEs
  n.sweeps = L(swl);
  cets = cell(1,n.sweeps);
  if verbose,
    fprintf_bullet('loading candidate events',2); p=0; t1=clock;
  end
  for ii=1:n.sweeps
    if verbose, p = print_progress(ii,n.sweeps,p); end
    ts = swl(ii).timestamp;  
    sweep_start_time = tss(ii);    
    cet = get_sweep_file(dirs, ts, 'candidate_events');
    cet.n_ces = L(cet.time_smp);
    cet.timestamps = repmat({ts},cet.n_ces,1);  
    cet.time_absolute_s = sweep_start_time + cet.time_ms/1000;
    cets{ii} = cet;
  end
  cets = cell2mat(cets);
  if verbose, fprintf_timediff(t1); end

  % initialise a structure to put them in
  n.ces = sum([cets.n_ces]);
  CEs = struct;
  [CEs.time_smp CEs.trigger CEs.time_ms CEs.time_absolute_s] = IA(nan(n.ces,1));
  CEs.timestamps = cell(n.ces, 1);
      
  % transfer
  count = 0;
  for ii=1:n.sweeps
    jjs = count + (1:cets(ii).n_ces);
    CEs.time_smp(jjs,:) = cets(ii).time_smp;
    CEs.time_ms(jjs,:) = cets(ii).time_ms;
    CEs.time_absolute_s(jjs,:) = cets(ii).time_absolute_s;
    CEs.trigger(jjs,:) = cets(ii).trigger;
    CEs.timestamps(jjs,:) = cets(ii).timestamps;
    count = count + cets(ii).n_ces;
  end
  
  % import shapes
  sh = get_sweep_file(dirs, ts, 'shapes');  
  CEs.shape = nan(n.ces, size(sh,2), size(sh,3), 'single');
  if verbose
    fprintf_bullet('loading shapes',2); p=0; t1=clock;
  end
  count = 0;
  for ii=1:n.sweeps
    if verbose, p = print_progress(ii,n.sweeps,p); end
    jjs = count + (1:cets(ii).n_ces);
    ts = swl(ii).timestamp;    
    sh = get_sweep_file(dirs, ts, 'shapes');
    CEs.shape(jjs,:,:) = sh;
    count = count + cets(ii).n_ces;
  end
  if verbose
    fprintf_timediff(t1);
  end
