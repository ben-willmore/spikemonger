function [fsp which_kept] = pefstemp(candidate_events,params)
 
%% PCA parameters
% =================

def.number_pc_per_channel = 2;
def.alignment_samples = 14 + (-5:5);
def.max_alignment_shift = 5;
def.pca_samples = 6:29;

% parse params
if nargin==1, params = struct; end
fd = fieldnames(def);
fp = fieldnames(params);

if ~isempty(setdiff(fp,fd))
  error('input:error',['unknown param field: ' head(setdiff(fp,fd))]);
end

p = def;
for ii=1:L(fp)
  p.(fp{ii}) = params.(fp{ii});
end


%% numbers
% =========

n = struct;
sh = candidate_events.shape;
s = size(sh);
n.events = s(1);
n.smp = s(2);
n.ch = s(3);



%% time shift
% ==============

% concatenate each individual event (across channels) into a single event
% vector. only keep the alignment samples.
sht = sh;
timeshift = zeros(n.events,1);

%{
sht(:,setdiff(1:n.smp,p.alignment_samples),:) = 0;

% find the mean event vector
mean_event = mean(reshape(sht,s(1),s(2)*s(3)));

% calculate cross-correlation of all events via matrix algebra
n.as = 2*p.max_alignment_shift+1;
xc = nan(n.events, n.as);
for ii=1:n.as
  as = pick(-p.max_alignment_shift:p.max_alignment_shift,ii);
  xc(:,ii) = reshape(sh,s(1),s(2)*s(3)) * circshift(mean_event',as);
end
[maxval maxpos] = max(xc,[],2);
timeshift = maxpos - (p.max_alignment_shift+1);

% set those with timeshift too big as having timeshift = 0
timeshift(abs(timeshift)==p.max_alignment_shift)=0;

% apply timeshift
sht = nan(n.events, n.smp+n.as-1, n.ch);
for ii=1:n.events
  sht(ii, -timeshift(ii)+p.max_alignment_shift+1+(1:40), :) = sh(ii,:,:);
end

% trim
sht = sht(:, p.pca_samples + p.max_alignment_shift, :);
%}

%% perform PCA
% ==============

% how many PCs we get in the end
s = size(sht);
n.ch = s(3);
n.pc = p.number_pc_per_channel;
n.total = n.ch * n.pc;

% proj = events in PC space
proj = nan(n.events,n.total);
for ii=1:n.ch
  jj = (ii-1)*n.pc + (1:n.pc);
  
  shtt = sq(sht(:,:,ii));
  c = cov(shtt);
  [v d] = eig(c);
  d = fliplr(diag(d)');
  v = fliplr(v);
  
  proj(:,jj) = shtt * v(:,1:n.pc);
end

%% put into struct
% ==================

fsp = proj;
which_kept = [];

%{
time_smp = candidate_events.time_smp + timeshift;

% get sweep ids
ts = candidate_events.timestamps;
[junk junk sweep_id] = unique(ts);

% run through sweep ids, and find unique events
n.sweeps = max(sweep_id);
tokeep_all = [];
for ii=1:n.sweeps
  [junk tokeep junk] = unique(time_smp(sweep_id==ii));
  tokeep_all = [tokeep_all; pick(find(sweep_id==ii),tokeep)];
end

% assemble these
tokeep = false(n.events,1);
tokeep(tokeep_all) = true;

% output
fsp = fsp(tokeep,:);
which_kept = tokeep_all;

%}