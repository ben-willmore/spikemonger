function B1_convert_f32s(dirs, varargin)
% B1_convert_f32s(dirs)
% B1_convert_f32s(root_directory)
% B1_convert_f32s(..., 'force_redo')
% B1_convert_f32s(..., 'parallel')
% B1_convert_f32s(..., 'regressed')

%% parse varargin
% ================

CAN_USE_PARALLEL = false;
FORCE_REDO = false;
REGRESSED = false;

try
  if nargin>1
    if any(ismember({'force_redo', 'forceredo', 'FORCE_REDO', ...
        'FORCEREDO', 'redo', 'REDO'}, varargin))
      FORCE_REDO = true;
    end
    if any(ismember({'parallel', 'can_use_parallel', 'PARALLEL', 'CAN_USE_PARALLEL'}, varargin))
      CAN_USE_PARALLEL = true;
    end
    if any(ismember({'regressed'}, varargin))
      REGRESSED = true;
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
if REGRESSED
  fprintf_subtitle(['(1) converting f32s from regressed']);
else
  fprintf_subtitle(['(1) converting f32s']);
end

% terminate if A1 has already been finished
if does_log_exist(dirs, 'A1.finished')
  fprintf_bullet('already done.\n');
  return;
end


%% convert the f32s
% =====================

if does_log_exist(dirs, 'A1.f32s.converted')
  fprintf('f32s already converted.\n');
  
  
else
  
  % directory contents
  if REGRESSED
    files = getfilelist(dirs.regressed_f32, 'f32');
  else
    files = getfilelist(dirs.raw_f32, 'f32');
  end
  files = files(~ismember({files.prefix}, {'nothing'}));
  n.files = L(files);
  mkdir_nowarning(dirs.sweeps);
  
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
  end

  % load metadata
  load([dirs.root 'gridInfo.mat']);

  sweep_files = getmatfilelist([dirs.root 'sweep.mat/']);
  for ii=1:L(sweep_files)
    sweep_idx = regexprep(sweep_files(ii).name, '^.*sweep.', '');
    sweep_idx = regexprep(sweep_idx, '.mat', '');
    sweep_idx = str2double(sweep_idx);
    sweep_files(ii).sweep_idx = sweep_idx;
  end
  [junk sort_idx] = sort([sweep_files.sweep_idx]);
  sweep_files = sweep_files(sort_idx);

  sweeps = cell(1, L(sweep_files));
  for ii=1:L(sweeps)
    swt = load(sweep_files(ii).fullname);
    sweeps{ii} = swt.sweep;
  end
  sweeps = cell2mat(sweeps);
  
  % try using parallel computation
  if CAN_USE_PARALLEL
    fprintf(['converting f32s (parallel):    [' n2s(n.files) ' files]:\n\n']);
    parfor ii=1:n.files
      convert_benware_f32(dirs, files(ii), ii, n.files); %#ok<*PFBNS>
    end
    
    % if no parallel computation available
  else
    fprintf('converting f32s (non-parallel):\n\n');
    for ii=1:n.files
      file = files(ii);
      sweep = sweeps(file.sweep_idx);
      fprintf_numbered(file.name, ii, n.files);
      convert_benware_f32(dirs, file, sweep)
    end
  end
  
  % write to log
  create_log(dirs, 'A1.f32s.converted');
  
end



%% aggregate metadata
% =====================

fprintf('\n\naggregating metadata:\n');

% aggregate sweep list
fprintf_bullet('creating sweep list...');

% load if it is already done
if does_log_exist(dirs, 'A1.swl.generated');
  swl = get_event_file(dirs, 'sweep_list');
  sweep_params = get_event_file(dirs, 'sweep_params');
  
% if not, create it
else
  swl = get_sweep_list(dirs);
  [sweep_params swl] = check_sweep_consistency(dirs, swl);
  save_event_file(dirs, swl, 'sweep_list');
  create_log(dirs, 'A1.swl.generated');
end
fprintf('[ok]\n');



%% detect candidate events
% ===========================

fprintf('\ndetecting candidate events:\n');

% already done?
if does_log_exist(dirs, 'A1.candidate.events.detected')
  fprintf_bullet('already done.\n');
  
else
  % try using parallel computation
  p = 0; t1 = clock;
  if CAN_USE_PARALLEL
    fprintf_bullet('searching through sweeps (parallel)...');
    parfor ii=1:L(swl)
      sfce(dirs, swl(ii));
    end
    
    
  % if no parallel computation available
  else
    fprintf_bullet('searching through sweeps (non-parallel)');
    % run through each sweep
    for ii=1:L(swl)
      p = print_progress(ii, L(swl), p);
      % retrieve the timestamp of the sweep
      timestamp = swl(ii).all_files(1).timestamp;
      % find candidate events and shapes
      candidate_events = find_candidate_events(dirs, swl(ii));
      shapes = candidate_events.shape;
      candidate_events = rmfield(candidate_events, 'shape');
      n_CEs = L(candidate_events.time_smp);
      % save them
      save_sweep_file(dirs, timestamp, candidate_events, 'candidate_events');
      save_sweep_file(dirs, timestamp, shapes, 'shapes');
      save_sweep_file(dirs, timestamp, n_CEs, 'n_CEs');
    end
  end
  
  % report that it is finished in the log
  create_log(dirs, 'A1.candidate.events.detected');
  fprintf_timediff(t1);
end


%% compile candidate event database
% ====================================


fprintf_bullet('compiling database:\n');
t1 = clock;
dirs = fix_dirs_struct(dirs);

if ~does_log_exist(dirs, 'A1.candidate.events.pentatrodes.compiled')
  
  % compile event database
  CEs = compile_candidate_event_database_for_large_data(dirs, swl);
  
  % calculate feature space representation for clustering dataset
  % ---------------------------------------------------------------
  
  % parameters
  params = struct;
  params.number_pc_per_channel = 3;
  params.max_alignment_shift = 2;
  params.alignment_samples = 14 + (-2:2);
  params.pca_samples = 5:30;
  params.include_absolute_time = true;
  params.include_trigger = true;
  params.include_trigger = false;
  params.use_pentatrodes = true;
  
  % design feature space
  if ~does_log_exist(dirs, 'A1.fsp.generated')
    [fsp params] = design_feature_space(CEs, params);
    save_event_file(dirs, fsp, 'feature_space_pentatrodes');
    save_event_file(dirs, params, 'feature_space_params');
    create_log(dirs, 'A1.fsp.generated');
  else
    params = get_event_file(dirs, 'feature_space_params');
  end
  
  % remove duplicates from CEs
  CEs = remove_duplicates_from_CEs(CEs, params);
  
  % save CEs
  save_event_file(dirs, CEs, 'candidate_events_pentatrodes');

  
  % calculate feature space representation for all data
  % -------------------------------------------------------
  
  fprintf_bullet('calculating feature space for each sweep');
  p = 0; t2 = clock;
  % run through sweeps
  for ii=1:L(swl)
    p = print_progress(ii, L(swl), p);
    params = try_rmfield(params, {'which_kept'});
    % compile for that sweep
    CEs = compile_candidate_event_database(dirs, swl(ii), 'silent', ...
      'reference_timestamp', swl(1).timestamp);
    [fsp params] = project_events_into_feature_space(CEs, params);
    CEs = remove_duplicates_from_CEs(CEs, params);
    % split into shape and non-shape
    CE_shapes = CEs.shape;
    CEs = try_rmfield(CEs, {'shape'});
    % save
    save_sweep_file(dirs, swl(ii).timestamp, fsp, 'fsp');
    save_sweep_file(dirs, swl(ii).timestamp, CEs, 'fsp_CEs');
    save_sweep_file(dirs, swl(ii).timestamp, CE_shapes, 'fsp_CE_shapes');
  end
  fprintf_timediff(t2);
  
  
  % done - add to log
  create_log(dirs, 'A1.candidate.events.pentatrodes.compiled');

  
end

fprintf_timediff(t1);
create_log(dirs, 'A1.finished');



end


%% HELPER FUNCTION for parallel
function sfce(dirs, swlt)
  timestamp = swlt.all_files(1).timestamp;
  candidate_events = find_candidate_events(dirs, swlt);
  shapes = candidate_events.shape;
  candidate_events = rmfield(candidate_events, 'shape');
  save_sweep_file(dirs, timestamp, candidate_events, 'candidate_events');
  save_sweep_file(dirs, timestamp, shapes, 'shapes');
end
