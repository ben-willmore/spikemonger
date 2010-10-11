function A1_convert_bwvts(dirs, varargin)
% A1_convert_bwvts(dirs)
% A1_convert_bwvts(root_directory)
%
% STAGE 1 OF SPIKEMONGER
%   - convert .src files to .mat

% ======================
% SPIKEMONGER v1.0.0.2
% ======================
%   - NCR 26-May-2010
%   - distributed under GPL v3 (see COPYING)


% parse varargin
% ================

CAN_USE_PARALLEL = false;
BWVTS_ONLY = false;

FORCE_REDO = false;
if nargin>1
  if any(ismember({'force_redo','forceredo','FORCE_REDO', ...
		   'FORCEREDO','redo','REDO'},varargin))
    FORCE_REDO = true;
  end
  if any(ismember({'parallel','can_use_parallel','PARALLEL','CAN_USE_PARALLEL'},varargin))
    CAN_USE_PARALLEL = true;
  end
  if any(ismember({'bwvts_only','bwvts','BWVTS','BWVTs', ...
		   'BWVTs_only'},varargin))
    BWVTS_ONLY = true;
  end
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
fprintf_subtitle(['(1) converting bwvts']);

% terminate if A1 has already been finished
if does_log_exist(dirs,'A1.finished')
  fprintf_bullet('already done.\n');
  return;
end




%% convert the bwvts
% =====================

if does_log_exist(dirs,'A1.bwvt.converted')
  fprintf('bwvts already converted.\n');
  
  
else

  % directory contents
  files = getfilelist(dirs.root,'bwvt');
  files = files(~ismember({files.prefix},{'nothing'}));
  n.files = L(files);
  mkdir_nowarning(dirs.sweeps);  

  try
    CAN_USE_PARALLEL;
  catch
    CAN_USE_PARALLEL = false;
  end

  % try using parallel computation
  if CAN_USE_PARALLEL
    fprintf(['converting bwvts (parallel):    [' n2s(n.files) ' files]:\n\n']);
    parfor ii=1:n.files    
      convert_bwvt(dirs, files(ii), ii, n.files); %#ok<*PFBNS>
    end

  % if no parallel computation available
  else
    fprintf('converting bwvts (non-parallel):\n\n');
    for ii=1:n.files
      file = files(ii);
      fprintf_numbered(file.name,ii,n.files);
      convert_bwvt(dirs, file, ii, n.files)
    end
  end

  % write to log
  create_log(dirs,'A1.bwvt.converted');

end

if BWVTS_ONLY
  return;
end

%% aggregate metadata
% =====================

fprintf('\n\naggregating metadata:\n');

% aggregate sweep list
fprintf_bullet('creating sweep list...');
if does_log_exist(dirs,'A1.swl.generated');
  swl = get_event_file(dirs,'sweep_list');
  sweep_params = get_event_file(dirs,'sweep_params');
else
  swl = get_sweep_list(dirs);
  [sweep_params swl] = check_sweep_consistency(dirs,swl);
  save_event_file(dirs,swl,'sweep_list');
  create_log(dirs,'A1.swl.generated');
end
fprintf('[ok]\n');

% check their consistency, and aggregate the sweep parameters



%% detect candidate events
% ===========================

fprintf('\ndetecting candidate events:\n');

% already done?
if does_log_exist(dirs,'A1.candidate.events.detected')
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
    for ii=1:L(swl)
      p = print_progress(ii,L(swl),p);
      timestamp = swl(ii).all_files(1).timestamp;
      candidate_events = find_candidate_events(dirs, swl(ii));
      shapes = candidate_events.shape;
      candidate_events = rmfield(candidate_events,'shape');
      save_sweep_file(dirs, timestamp, candidate_events, 'candidate_events');
      save_sweep_file(dirs, timestamp, shapes, 'shapes');
    end  
  end

  % report that it is finished in the log
  create_log(dirs,'A1.candidate.events.detected');
  fprintf_timediff(t1);
end


%% compile candidate event database
% ====================================

fprintf_bullet('compiling database:\n');
t1 = clock;
dirs = fix_dirs_struct(dirs);

if ~does_log_exist(dirs,'A1.candidate.events.pentatrodes.compiled')
  
  % create a memory workaround if necessary
  % ------------------------------------------
  if ~does_log_exist(dirs, 'A1.candidate.events.memory.workaround')
    
    CEs = compile_candidate_event_database(dirs, swl);

    % stopgap in case there may be memory issues, by saving CEs to disk. this
    % ensures that when we call the PCA function, we don't have to hold two
    % copies of CEs in memory. These files must then be reloaded inside
    % project_events_into_feature_space
    MAX_CE_SIZE = 5e5;
    if L(CEs.time_smp) > MAX_CE_SIZE
      s = size(CEs.shape);
      fprintf_bullet('memory workaround',2); p=0; t2=clock;
      for ii=1:s(3)
        p = print_progress(ii,s(3),p);
        sh = sq(CEs.shape(:,:,ii));
        save_event_file(dirs,sh,['CEs_MW_sh' n2s(ii,2)]);
      end
      fprintf_timediff(t2);
      CEs = rmfield(CEs,'shape');
      save_event_file(dirs,CEs,'CEs_MW_main');
      save_event_file(dirs,s,'CEs_MW_shape_size');
      CEs = []; sh = [];
      memory_workaround = true;
      create_log(dirs,'A1.candidate.events.memory.workaround');
    else
      memory_workaround = false;
      delete_log(dirs,'A1.candidate.events.memory.workaround');
    end
  
  else
    CEs = [];
  end
  
  
  % memory workaround type 2
  if does_log_exist(dirs, 'A1.candidate.events.memory.workaround') & ~does_log_exist(dirs, 'A1.candidate.events.memory.workaround.2')
    create_MW_2(dirs);
    create_log(dirs,'A1.candidate.events.memory.workaround.2');
  end
  
  
  % calculate feature space representation
  params = struct;
  params.number_pc_per_channel = 3;
  params.max_alignment_shift = 2;
  params.alignment_samples = 14 + (-2:2);
  params.pca_samples = 5:30;
  params.include_absolute_time = true;
  params.include_trigger = true;
  params.include_trigger = false;    

  % feature space - pentatrodes
  if ~does_log_exist(dirs,'A1.fsp.generated')
    params.use_pentatrodes = true;  
    if isempty(CEs) & does_log_exist(dirs, 'A1.candidate.events.memory.workaround')
      [fsp which_kept params] = project_events_into_feature_space_MW(params,dirs);
    else
      [fsp which_kept params] = project_events_into_feature_space(params,dirs);
    end
    save_event_file(dirs,fsp,'feature_space_pentatrodes');
    save_event_file(dirs,which_kept,'which_kept');
    create_log(dirs,'A1.fsp.generated');
  else
    which_kept = get_event_file(dirs,'which_kept');
  end

  
  % reload CEs if we are in the memory workaround  
  if does_log_exist(dirs, 'A1.candidate.events.memory.workaround')
    clear fsp;    
    fprintf_bullet('reloading CEs',2); 
    CEs = get_event_file(dirs,'CEs_MW_main'); 
%     p = 0; t2 = clock;
%     s = get_event_file(dirs,'CEs_MW_shape_size');
%     CEs.shape = nan(s(1),s(2),s(3),'single');
%     for ii=1:s(3)
%       p = print_progress(ii,s(3),p);
%       CEs.shape(:,:,ii) = get_event_file(dirs,['CEs_MW_sh' n2s(ii,2)]);
%     end  
%    fprintf_timediff(t2);
  end
  
  
  % remove duplicates from CEs - pentatrodes
  fprintf_bullet('removing duplicates',2); t2=clock;
  CEs.time_smp = CEs.time_smp(which_kept); fprintf('.');
  CEs.time_ms  = CEs.time_ms(which_kept); fprintf('.');
  CEs.time_absolute_s = CEs.time_absolute_s(which_kept,:); fprintf('.');
  CEs.trigger  = CEs.trigger(which_kept); fprintf('.');
  if ~does_log_exist(dirs, 'A1.candidate.events.memory.workaround')
      CEs.shape    = CEs.shape(which_kept,:,:); fprintf('.');
  end
  CEs.timestamps = CEs.timestamps(which_kept); fprintf('.');
  CEs.fsp_params = params;
  save_event_file(dirs,CEs,'candidate_events_pentatrodes');  fprintf('.'); 
  create_log(dirs,'A1.candidate.events.pentatrodes.compiled');
      fprintf('.');
  fprintf_timediff(t2);
  
end

fprintf_timediff(t1);


%% delete sweeps
% ================

fprintf_bullet('cleaning up...');
rmdir(dirs.sweeps,'s');
fprintf('[ok]\n');

create_log(dirs,'A1.finished');



end


%% HELPER FUNCTION
function sfce(dirs,swlt)
  timestamp = swlt.all_files(1).timestamp;
  candidate_events = find_candidate_events(dirs, swlt);
  shapes = candidate_events.shape;
  candidate_events = rmfield(candidate_events,'shape');
  save_sweep_file(dirs, timestamp, candidate_events, 'candidate_events');
  save_sweep_file(dirs, timestamp, shapes, 'shapes');
end
