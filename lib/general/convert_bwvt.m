function convert_bwvt(dirs, file, count, maxcount)
  % data = import_bwvt(dirs, file)
  % data = import_bwvt(dirs, file, count, maxcount)
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)
  
  
%% params
% ========

% sample rate
dt = 0.040959999071638; % ms
fs = 1000/dt;           % Hz


%% parse filename and directory
% ================================

dirs = fix_dirs_struct(dirs);

% does the source file exist?
if ~exist(file.fullname,'file')
  error('file:error','file does not exist');
end
  

%% import from bwvt
% ==================

% import
bwvt = readBWVTfile(file.fullname);
  
% add datestamp
for ii=1:L(bwvt)
  bwvt(ii).timestamp = parse_timestamp(bwvt(ii).timeStamp,'str');
end
try
  bwvt = rmfield(bwvt,'timeStamp');
catch
  error('bwvt:error','bad size bwvt');
end
  

%% extract metadata
% ===================

% sweep parameter values, as recorded by brainware
params.sweep.all = reach(bwvt,'stim.paramVal');
[a b c] = unique(params.sweep.all','rows');
params.sweep.unique = a';
params.sweep.index  = c';

% sweep parameters
params.sweep.names = bwvt(1).stim.paramName';
for ii=1:L(params.sweep.names)
  params.sweep.names{ii} = make_into_nice_field_name( params.sweep.names{ii} );
end
n.params = L(params.sweep.names);


%{
% Skip this section, and do it on the dataset from all bwvts

% how many sets (ie unique sweeps)
n.sets = L(unique(c));
n.repeats_per_set = zeros(1,n.sets);
for ii=1:n.sets
  n.repeats_per_set(ii) = sum(c==ii);
end

% set parameters
params.set.all = params.sweep.unique;
params.set.names = params.sweep.names;
%}

%% run through each sweep
% =========================

p = 0; t1 = clock; 

if nargin==2
  fprintf_bullet('extracting and filtering signals');
elseif nargin==4
  fprintf_bullet(['[' n2s(count) '/' n2s(maxcount) ']  extracting and filtering signals']);
end
  
for ii=1:L(bwvt)
  
  p = print_progress(ii,L(bwvt),p);
  
  % target file
  swf = struct;
  swf.bwvt_source = file.prefix;
  swf.timestamp = bwvt(ii).timestamp;    

  % does the destination file exist?
  if does_sweep_file_exist(dirs, swf, 'filtered_signal')    
    continue;
  end

  % sweep params
  sweep_params = struct;
  sweep_params.all.values = params.sweep.all(:,ii);
  sweep_params.all.names  = params.sweep.names;
  fields = sweep_params.all.names;
  for ff=1:L(fields)
    sweep_params.(fields{ff}) = sweep_params.all.values(ff);
  end
  sweep_params.length_signal_smp = L(bwvt(ii).signal);
  sweep_params.length_signal_ms  = L(bwvt(ii).signal) * dt;
  sweep_params.all.values = sweep_params.all.values';
  sweep_params.all.names = sweep_params.all.names';
  save_sweep_file(dirs, swf, sweep_params, 'sweep_params');
  
  % filtered signal
  filtered_signal = bandpass_for_spikes(bwvt(ii).signal,fs);
  save_sweep_file(dirs, swf, filtered_signal, 'filtered_signal');
  
  
end
fprintf(['[' timediff(t1,clock) ']\n']);