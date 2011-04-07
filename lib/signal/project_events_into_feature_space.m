function [fsp p] = project_events_into_feature_space(CEs, params)
  

%% PCA parameters
% =================

% default parameters
def.number_pc_per_channel = 2;
def.alignment_samples = 14 + (-5:5);
def.max_alignment_shift = 5;
def.pca_samples = 6:29;
def.trigger_refractory_samples = 3;
def.include_absolute_time = false;
def.include_trigger = false;
def.use_pentatrodes = false;
% these must be there
def.mean_event = [];
def.v = [];

% parse params
if nargin==1, params = struct; end
fd = fieldnames(def);
fp = fieldnames(params);

% error if there are bad fields
if ~isempty(setdiff(fp,fd))
  error('input:error',['unknown param field: ' pick(setdiff(fp,fd),1,'c')]);
end

% error if required fields are missing
if ~ismember('mean_event',fp)
  error('input:error','missing param field: mean_event');
elseif ~ismember('v',fp)
  error('input:error','missing param field: v (eigenvectors)');
end

% used parameters
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

% check that the mean vector is the right length
if n.events > 0
if ~( numel(CEs.shape(1,:,:)) == L(p.mean_event) )
  error('input:error', 'mean event has the wrong number of elements');
end
end


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


%% apply timeshift and trim

ti = p.pca_samples(1) + timeshift - 1;
tf = ti + L(p.pca_samples) - 1;
sht = nan(n.events, L(p.pca_samples + p.max_alignment_shift), n.ch, 'single');
for ii=1:n.events
  sht(ii,:,:) = CEs.shape( ii, ti(ii):tf(ii), :, :);
end


%% project into fsp
% ====================

% how many PCs we get in the end
s = size(sht);
n.ch = s(3);
n.pc = p.number_pc_per_channel;
n.total = n.ch * n.pc;

% fsp = events in PC space
fsp = nan(n.events,n.total);
for ii=1:n.ch
  jj = (ii-1)*n.pc + (1:n.pc);  
  shtt = sq(sht(:,:,ii));
  fsp(:,jj) = shtt * p.v{ii};
end


%% include trigger and absolute time, if requested
% ==================================================

if p.include_trigger
  fsp = [fsp CEs.trigger];
end

if p.include_absolute_time
  fsp = [fsp CEs.time_absolute_s];
end

%% put into struct, if not pentatrodes
% ======================================

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
  which_kept = tokeep_all;

end


%% put into struct, if pentatrodes
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
  p.which_kept = find(tokeep);
  
end