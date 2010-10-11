function [fsp which_kept p] = project_events_into_feature_space_MW(params,dirs)
 
fprintf_bullet('projecting into feature space\n',2);


%% load basics
% ==============

fprintf_bullet('loading basics...',3); t1=clock;
CEs_all = get_event_file(dirs,'CEs_MW_main');
s = get_event_file(dirs,'CEs_MW_shape_size');
fprintf_timediff(t1);
  

%% PCA parameters
% =================

def.number_pc_per_channel = 2;
def.alignment_samples = 14 + (-5:5);
def.max_alignment_shift = 5;
def.pca_samples = 6:29;
def.trigger_refractory_samples = 3;
def.include_absolute_time = false;
def.include_trigger = false;
def.use_pentatrodes = false;

% parse params
if nargin==1, params = struct; end
fd = fieldnames(def);
fp = fieldnames(params);

if ~isempty(setdiff(fp,fd))
  error('input:error',['unknown param field: ' pick(setdiff(fp,fd),1,'c')]);
end

p = def;
for ii=1:L(fp)
  p.(fp{ii}) = params.(fp{ii});
end


%% numbers
% =========

n = struct;
n.events = s(1);
n.smp = s(2);
n.ch = s(3);

n.pc = p.number_pc_per_channel;
n.total = n.ch * n.pc;

%% calculate timeshift
% =======================

MWallfiles = getfilelist(dirs.events,'CEs_MW_all','p');
n.mwall = L(MWallfiles);

ts = cell(n.mwall,1);
fprintf_bullet('calculating timeshift',3); t1=clock;

for aa=1:n.mwall
  fprintf('.');
  
  CEs = load(MWallfiles(aa).fullname);
  CEs = CEs.(pick(fieldnames(CEs),1,'c'));


  % apply pentatrode config, if requested
  % ----------------------------------------


  % zero out shapes outside the pentatrode
  if p.use_pentatrodes
    for cc=1:n.ch    
      % which events are triggered on that channel
      which_events = (CEs.trigger == cc);
      % which channels need to be zeroed
      which_channels = ~ismember(1:n.ch, cc+(-2:2));
      % zero
      CEs.shape(which_events, :, which_channels) = 0;
    end
  end

  % time shift
  % --------------

  % if this is the first one, calculate the time shift
  if aa==1

    % concatenate each individual event (across channels) into a single event
    % vector. only keep the alignment samples.
    sht = CEs.shape;
    sht(:,setdiff(1:n.smp,p.alignment_samples),:) = 0;

    % find the mean event vector
    s = size(sht);
    mean_event = mean(reshape(sht,s(1),s(2)*s(3)));

  end


  s = size(CEs.shape);
  % for each event, calculate the best time shift for maximum alignment with
  % the mean event vector.

  % calculate cross-correlation of all events via matrix algebra
  n.as = 2*p.max_alignment_shift+1;
  xc = nan(s(1), n.as);
  for ii=1:n.as
    as = pick(-p.max_alignment_shift:p.max_alignment_shift,ii);
    xc(:,ii) = reshape(CEs.shape,s(1),s(2)*s(3)) * circshift(mean_event',as);
  end
  [maxval maxpos] = max(abs(xc),[],2);
  timeshift = maxpos - (p.max_alignment_shift+1);

  % set those with timeshift too big as having timeshift = 0
  timeshift(abs(timeshift)==p.max_alignment_shift)=0;

  ts{aa} = timeshift;

end
timeshift = cell2mat(ts);
fprintf_timediff(t1);


%% perform PCA on each channel in turn


fprintf_bullet('calculating PCAs',3); t1=clock;


fsp = nan(n.events,n.total);

for cc = 1:n.ch
  fprintf('.');
  
  % load channel file
  sh = get_event_file(dirs,['CEs_MW_sh' n2s(cc,2)]);  
  
  % apply pentatrode config
  if p.use_pentatrodes
    sh(~ismember(CEs_all.trigger,(cc-2):(cc+2))) = 0;
  end
    
  % apply timeshift and trim  
  ti = p.pca_samples(1) + timeshift - 1;
  tf = ti + L(p.pca_samples) - 1;
  sht = nan(n.events, L(p.pca_samples + p.max_alignment_shift), 'single');
  for ii=1:n.events
    sht(ii,:) = sh( ii, ti(ii):tf(ii) );
  end  
  
  % perform PCA  
  jj = (cc-1)*n.pc + (1:n.pc);  
  c = cov(sht);
  try
    [v d] = eig(c);
  catch
    v = randn(s(2));
    d = randn(s(2));
  end
  d = fliplr(diag(d)');
  v = fliplr(v);
  
  % add to fsp
  fsp(:,jj) = sht * v(:,1:n.pc);
  
end

fprintf_timediff(t1);



%% include trigger and absolute time, if requested
% ==================================================

if p.include_trigger
  fsp = [fsp CEs_all.trigger];
end

if p.include_absolute_time
  fsp = [fsp CEs_all.time_absolute_s];
end

%% put into struct, if not pentatrodes
% ======================================

if ~p.use_pentatrodes

  time_smp = CEs_all.time_smp + timeshift;

  % get sweep ids
  ts = CEs_all.timestamps;
  [junk junk sweep_id] = unique(ts);

  % run through sweep ids, and find unique events (with a trigger refractory
  % period)
  n.sweeps = max(sweep_id);
  tokeep_all = [];
  for ii=1:n.sweeps
    %[junk tokeep junk] = unique(time_smp(sweep_id==ii));
    [junk tokeep] = unique_within(time_smp(sweep_id==ii), p.trigger_refractory_samples);
    tokeep_all = [tokeep_all; pick(find(sweep_id==ii),tokeep)];
  end

  % assemble these
  tokeep = false(n.events,1);
  tokeep(tokeep_all) = true;

  % output
  fsp = fsp(tokeep,:);
  which_kept = tokeep_all;

end


%% put into struct, if pentatrodes
% ======================================

if p.use_pentatrodes
  
  time_smp = CEs_all.time_smp + timeshift;

  % get sweep ids
  ts = CEs_all.timestamps;
  [junk junk sweep_id] = unique(ts);
  
  % run through sweep ids, and find unique events (with a trigger refractory
  % period)
  n.sweeps = max(sweep_id);
  tokeep = true(n.events,1);
  
  % just look at one sweep, one electrode subgroup
  fprintf_bullet('looking for duplicates',3); t1=clock; pr=0;
  for ii=1:n.sweeps
    pr = print_progress(ii,n.sweeps,pr);
    this = struct;
    this.sweep = (sweep_id==ii);
    for gg=1:n.ch-2
      ccs=(gg:(gg+2));
      this.subgroup = ismember(CEs_all.trigger,ccs);      
      this.to_consider = this.sweep & this.subgroup & tokeep;
      this.to_consider_idx = find(this.to_consider);
      this.n_events = sum(this.to_consider);
      t = time_smp(this.to_consider);
      [t2, this.which_kept] = unique_within(t, p.trigger_refractory_samples);
      this.which_discarded = setdiff(1:this.n_events, this.which_kept);
      this.which_discarded_idx = this.to_consider_idx(this.which_discarded);
      
      tokeep(this.which_discarded_idx) = false;
    end
  end
  fprintf_timediff(t1);
  
  % output
  fsp = fsp(tokeep,:);
  which_kept = find(tokeep);
  
end