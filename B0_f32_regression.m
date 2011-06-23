function B0_f32_regression(dirs, varargin)
% B0_f32_regression(dirs)
% B0_f32_regression(root_directory)

% parse varargin
% ================

CAN_USE_PARALLEL = false;
FORCE_REDO = false;
try
  if nargin>1
    if any(ismember({'force_redo','forceredo','FORCE_REDO', ...
        'FORCEREDO','redo','REDO'},varargin))
      FORCE_REDO = true;
    end
    if any(ismember({'parallel','can_use_parallel','PARALLEL','CAN_USE_PARALLEL'},varargin))
      CAN_USE_PARALLEL = true;
    end
  end
catch
end

%% prelims
% ===========

% parse dirs
try
  dirs = fix_dirs_struct(dirs);
catch
  dirs = fix_dirs_struct(dirs.root);
end

% title
fprintf_subtitle(['(0) f32 regression']);

% terminate if A1 has already been finished
if does_log_exist(dirs,'A0.finished')
  fprintf_bullet('already done.\n');
  return;
end


%% file list
% =====================

% directory contents
files = getfilelist(dirs.raw_f32, 'f32');
if L(files)==0
  files = getfilelist(dirs.raw_f32, 'mat');
  if L(files)==0
    error('file:error','no files here');
  end
  use_mat = true;
else
  use_mat = false;
end

files = files(~ismember({files.prefix},{'nothing'}));
n.files = L(files);
mkdir_nowarning(dirs.regressed_f32);

% parse filenames
for ii=1:L(files)
  sweep_idx = regexprep(files(ii).name, '^.*sweep.', '');
  sweep_idx = regexprep(sweep_idx, '.channel.*', '');
  sweep_idx = str2double(sweep_idx);
  files(ii).sweep_idx = sweep_idx;

  channel_idx = regexprep(files(ii).name, '^.*channel.', '');
  channel_idx = regexprep(channel_idx, '.f32', '');
  channel_idx = str2double(channel_idx);
  files(ii).channel_idx = channel_idx;

  files(ii).recording_name = regexprep(files(ii).prefix, '.sweep.*', '');
  files(ii).target_name = [dirs.regressed_f32 files(ii).name];
end  

% adjust sweep numbers in case they came from different sources
max_sweep_idx = max(unique([files.sweep_idx])) + 1;
recording_names = unique({files.recording_name});
[junk rec_nums] = ismember({files.recording_name}, recording_names);
for ii=1:L(files)
  files(ii).sweep_idx = files(ii).sweep_idx + (rec_nums(ii) - 1)*max_sweep_idx;
end

sweep_idxs = unique([files.sweep_idx]);
channel_idxs = unique([files.channel_idx]);
n.e = L(channel_idxs);
n.s = L(sweep_idxs);

%% f32 regression
% ==================

% run through each sweep number
fprintf_bullet('regressing f32s');
p = 0; t1 = clock;
for ss=1:n.s
  p = print_progress(ss, n.s, p);
  sweep_idx = sweep_idxs(ss);
  
  % files in this sweep, sorted
  filest = files([files.sweep_idx]==sweep_idx);
  [junk sort_order] = sort([filest.channel_idx]);
  filest = filest(sort_order);
  
  % check that these all come from the same recording
  if L(unique({filest.recording_name})) > 1
    fprintf('problem: these come from diff recordings -- fix.\n');
    keyboard;
  end

  
  % collect f32s
  signals = cell(1, n.e);
  for ii=1:n.e
    fid = fopen(filest(ii).fullname);
    signal = fread(fid, inf, 'float32');
    fclose(fid);
    signals{ii} = signal;
  end
  
  % collect signals
  signals = cell2mat(signals);
  n.samples = size(signals, 1);
  n.reg_samples = round(n.samples/10);
  
  regressed_signals = zeros(size(signals));
  
  % regress outside the pentatrode, using random subset
  for ii=1:n.e
    tok = randsample(n.samples, n.reg_samples);
    y = signals(tok, ii);
    jj = setdiff(1:n.e, ii+(-2:2));
    x = [signals(tok, jj), ones(n.reg_samples,1)];
    b = regress(y,x);
    % correct the f32
    regressed_signals(:, ii) = signals(:,ii) - [signals(:, jj), ones(n.samples,1)] * b;
  end
  
  % save the f32s
  for ii=1:n.e
    fid = fopen(filest(ii).target_name, 'w');
    fwrite(fid, regressed_signals(:, ii), 'float32');
    fclose(fid);
  end
  
end
fprintf_timediff(t1);
