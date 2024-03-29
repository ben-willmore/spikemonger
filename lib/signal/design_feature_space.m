function [fsp p conditional_distributions] = design_feature_space(CEs, params)
  % [fsp params] = design_feature_space(CEs, params)
  
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
try
  if nargin==1, params = struct; end
catch
end
fd = fieldnames(def);
fp = fieldnames(params);

% are there any bad params
if ~isempty(setdiff(fp,fd))
  error('input:error',['unknown param field: ' pick(setdiff(fp,fd),1,'c')]);
end

% make the param structure
p = def;
for ii=1:L(fp)
  p.(fp{ii}) = params.(fp{ii});
end


%% numbers
% =========

n = struct;
s = size(CEs.shape);
n.events = s(1);
n.smp = s(2);
n.ch = s(3);


%% apply pentatrode config, if requested
% =========================================

% zero out shapes outside the pentatrode
if p.use_pentatrodes
  % save original data so we can use it to calculate
  % conditional distributions later on
  orig_shape = CEs.shape;

  for cc=1:n.ch    
    % which events are triggered on that channel
    which_events = (CEs.trigger == cc);
    % which channels need to be zeroed
    which_channels = ~ismember(1:n.ch, cc+(-2:2));
    % zero
    CEs.shape(which_events, :, which_channels) = 0;
  end
end


%% time shift
% ==============

% concatenate each individual event (across channels) into a single event
% vector. only keep the alignment samples.
sht = CEs.shape;
sht(:,setdiff(1:n.smp,p.alignment_samples),:) = 0;

% find the mean event vector
p.mean_event = mean(reshape(sht,s(1),s(2)*s(3)));
clear sht;

% for each event, calculate the best time shift for maximum alignment with
% the mean event vector.

% calculate cross-correlation of all events via matrix algebra
n.as = 2*p.max_alignment_shift+1;
xc = nan(n.events, n.as);
for ii=1:n.as
  as = pick(-p.max_alignment_shift:p.max_alignment_shift,ii);
  xc(:,ii) = reshape(CEs.shape,s(1),s(2)*s(3)) * circshift(p.mean_event',as);
end
[maxval maxpos] = max(abs(xc),[],2);
timeshift = maxpos - (p.max_alignment_shift+1);

% set those with timeshift too big as having timeshift = 0
timeshift(abs(timeshift)==p.max_alignment_shift)=0;


% apply timeshift and trim
ti = p.pca_samples(1) + timeshift - 1;
tf = ti + L(p.pca_samples) - 1;
sht = nan(n.events, L(p.pca_samples + p.max_alignment_shift), n.ch, 'single');
for ii=1:n.events
  sht(ii,:,:) = CEs.shape( ii, ti(ii):tf(ii), :, :);
end

% apply same timeshift and trim unzeroed data
if p.use_pentatrodes
  orig_sht = nan(n.events, L(p.pca_samples + p.max_alignment_shift), n.ch, 'single');
  for ii=1:n.events
    orig_sht(ii,:,:) = orig_shape( ii, ti(ii):tf(ii), :, :);
  end
end

%% perform PCA
% ==============

% how many PCs we get in the end
s = size(sht);
n.ch = s(3);
n.pc = p.number_pc_per_channel;
n.total = n.ch * n.pc;

% container for eigenvectors
v = cell(1,n.ch);

% fsp = events in PC space
fsp = nan(n.events,n.total);

if p.use_pentatrodes
  fsp_orig = fsp;
end

for ii=1:n.ch
  jj = (ii-1)*n.pc + (1:n.pc);
  % just data in this channel
  shtt = sq(sht(:,:,ii));
  % perform PCA
  c = cov(shtt);
  try
    [vt d] = eig(c);
  catch
    vt = randn(s(2));
    dt = randn(s(2));
  end
  % put in correct order
  %d = fliplr(diag(d)');
  vt = fliplr(vt);
  % save eigenvector
  v{ii} = vt(:,1:n.pc);
  % project into feature space
  fsp(:,jj) = shtt * v{ii};

  % project non-zeroed data into feature space
  if p.use_pentatrodes
    orig_shtt = sq(orig_sht(:,:,ii));
    fsp_orig(:,jj) = orig_shtt * v{ii};
  end
end

if ~p.use_pentatrodes
  fsp_orig = fsp;
end

% save eigenvectors
p.v = v;

%% include trigger and absolute time, if requested
% ==================================================

if p.include_trigger
  fsp = [fsp CEs.trigger];
  fsp_orig(:, end+1) = nan;
end

if p.include_absolute_time
  fsp = [fsp CEs.time_absolute_s];
  fsp_orig(:, end+1) = nan;
end

%% find unique events, if not pentatrodes
% =========================================

if ~p.use_pentatrodes

  time_smp = CEs.time_smp + timeshift;

  % get sweep ids
  ts = CEs.timestamps;
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
  fsp_orig = fsp_orig(tokeep,:);
  which_kept = tokeep_all;

end


%% find unique events, if pentatrodes
% ======================================

if p.use_pentatrodes
  
  time_smp = CEs.time_smp + timeshift;

  % get sweep ids
  ts = CEs.timestamps;
  [junk junk sweep_id] = unique(ts);
  
  % run through sweep ids, and find unique events (with a trigger refractory
  % period)
  n.sweeps = max(sweep_id);
  tokeep = true(n.events,1);
  
  % just look at one sweep, one electrode subgroup
  for ii=1:n.sweeps
    this = struct;
    this.sweep = (sweep_id==ii);
    for gg=1:n.ch-2
      ccs=(gg:(gg+2));
      this.subgroup = ismember(CEs.trigger,ccs);      
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
  
  % output
  fsp = fsp(tokeep,:);
  fsp_orig = fsp_orig(tokeep,:);
  p.which_kept = find(tokeep);
  
end

%% calculate distributions of voltages, conditioned
%% on trigger channel
% ===================================================

conditional_distributions.mean = nan(size(fsp, 2), n.ch);
conditional_distributions.sd = nan(size(fsp, 2), n.ch);
trigger = CEs.trigger(p.which_kept);
assert(length(trigger)==size(fsp,1));
assert(all(size(fsp)==size(fsp_orig)));

for trigger_channel = 1:n.ch
  which_events = trigger==trigger_channel;
  ev = fsp_orig(which_events,:);
  conditional_distributions.mean(:, trigger_channel) = mean(ev);
  conditional_distributions.sd(:, trigger_channel) = std(ev);
end
