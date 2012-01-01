function cluster_ui(rootdir)

setpath;

if ~exist('rootdir', 'var')
    % rootdir, based on source computer
    compname = get_current_computer_name;
    if strcmp(compname, 'macgyver');
      rootdir = '/shub/experiments/data.expt35/ctuning/';
    elseif strcmp(compname, 'blueweasel');
      rootdir = 'data/';
    elseif strcmp(compname, 'welshcob');
        rootdir = 'sandra/';    
    elseif strcmp(compname, 'chai');
        rootdir = '/wocka/resorting/';
    end
end

% use the file browser
sourcedir = pickdir_for_cluster_ui(rootdir);
dirs = fix_dirs_struct(sourcedir);
dirs.cluster = [dirs.root 'clusters_pentatrodes' filesep];

% source and destination paths
dirs.cluster_source = dirs.cluster;
dirs.cluster_dest   = [dirs.root 'clusters.' datestr(now, 'yyyy-mm-dd.HHMM') filesep];
mkdir_nowarning(dirs.cluster_dest);


%% parameters
% ===============

MAX_N_SHAPES = 10;
MAX_N_FSP = 200;


%% get source data
% ===================

% get clusters
files = getmatfilelist(dirs.cluster);
for ii=1:L(files)
  files(ii).cluster = str2double(files(ii).name(9:10));
  files(ii).type = files(ii).name(12:(end-4));
end
n.c = max([files.cluster]);
fprintf('\n');
fprintf_bullet(['loading ' n2s(sum(ismember({files.type}, 'data'))) ' clusters: ']);

% types of data available
types = unique({files.type})';

% colors
cols = hsv(n.c);
cols = cols(randperm(n.c), :);

% get data
[C.fsp C.sh C.sh_mean C.psth C.acgs C.isis C.sve ...
  C.data C.sweep_count C.trigger C.shape_correlation] ...
  = IA(cell(1, n.c));
for cc=1:n.c
  fprintf(n2s(cc));
  if cc<n.c, fprintf('/'); end
  
  C.sh{cc} = get_cluster_file(dirs, cc, 'event_shape');
  s = size(C.sh{cc});
  C.shape_correlation{cc} = mean(nondiag(corrcoef(reshape(C.sh{cc}, [s(1)*s(2) s(3)]))));
  C.sh_mean{cc} = sq(mean(C.sh{cc}, 1));
  C.fsp{cc} = get_cluster_file(dirs, cc, 'event_fsp');
  C.psth{cc} = get_cluster_file(dirs, cc, 'psth_all_sets');
  C.acgs{cc} = get_cluster_file(dirs, cc, 'ACGs');  
  C.isis{cc} = get_cluster_file(dirs, cc, 'ISIs');
  C.data{cc} = get_cluster_file(dirs, cc, 'data');  
  try
      C.sve{cc} = get_cluster_file(dirs, cc, 'sahani_variance_explainable');
  catch
      C.sve{cc} = sahani_variance_explainable_2(C.data{cc});
      save_cluster_file(dirs, cc, C.sve{cc}, 'sahani_variance_explainable');
  end
  C.trigger{cc} = get_cluster_file(dirs, cc, 'event_trigger');
  
  % for sweep-spike counts
  if cc==1
    n.sweeps = sum(Lincell({C.data{1}.set.repeats}));
  end
  C.sweep_count{cc} = hist(get_cluster_file(dirs, cc, 'event_sweep_id'), 1:n.sweeps);
  
  % limit shapes to MAX_N_SHAPES  
  n_shapes_total  = size(C.sh{cc}, 1);
  n_shapes_tokeep = min(n_shapes_total, MAX_N_SHAPES);
  tokeep          = head(randperm(n_shapes_total), n_shapes_tokeep);
  C.sh{cc}        = C.sh{cc}(tokeep, :, :);
  
  % limit fsp to MAX_N_FSP
  n_fsp_total  = size(C.fsp{cc}, 1);
  n_fsp_tokeep = min(n_fsp_total, MAX_N_FSP);
  tokeep       = head(randperm(n_fsp_total), n_fsp_tokeep);
  C.fsp{cc}     = C.fsp{cc}(tokeep, :);
end


% convert to struct
C.shape_correlation = cell2mat(C.shape_correlation);
C.psth = cell2mat(C.psth);
C.sve = cell2mat(C.sve);
C.acgs = cell2mat(C.acgs);
C.isis = cell2mat(C.isis);
C.data = cell2mat(C.data);

% list of variables available for clusters
varlist = fieldnames(C);
n.vars  = L(varlist);

% some parameters
n.dims = size(C.fsp{1}, 2);
n.channels = size(C.sh{1}, 3);
% sort by position
estimated_pos = pos_in_fsp(C.sh_mean);
[junk sort_idx] = sort(estimated_pos);
[junk ids.source_clusters] = sort(sort_idx);

% sort
for vv=1:n.vars  
  C.(varlist{vv}) = C.(varlist{vv})(sort_idx);
end

% colors
cols = hsv(n.c);
cols = cols(randperm(n.c), :);

% prepare first backup
C_backup = C;
C_init   = C;
history = {};

fprintf('[ok]\n');


%% ask what to do
% =================

continue_loop = true;

while continue_loop
  
  % exit if there are no more clusters
  n.c = L(C.fsp);
  if n.c==0, break; end
  
  n.sweeps = L(C.sweep_count{1});    
  
  % request action
  todo = request_action_main(n, dirs);  
  history = update_history(history, todo, dirs);
  
  if isempty(todo)
    continue;
  end
  
  switch todo{1}
    
    case '0' % close all plots
      close all;
      
    case 'p' % close and replot
      close all;
      ctp = 1:n.c;
      p2 = plot_clusters_waveforms(C.sh, C.sh_mean, cols, ctp, C.sweep_count, C.shape_correlation);
      p3 = plot_clusters_psth_all(C.psth, C.sve, cols, ctp);
      p4 = plot_clusters_isi(C.isis, cols, ctp);
      p5 = plot_clusters_time_changes(C.sweep_count, cols, ctp);
      p6 = plot_clusters_trigger(C.trigger, cols, ctp, n);
    
    case {'1', '2', '3'} % plot
      % which clusters to plot
      if isequal(todo{1}, '1')
        ctp = 1:n.c;
      elseif isequal(todo{1}, '2')
        ctp = todo{3};
      elseif isequal(todo{1}, '3')
        ctp = cell2mat(todo(3:end));
      end
      
      % which plots
      switch todo{2}
        case 1
          p = plot_clusters_in_fsp(C.fsp, cols, ctp);
        case 2
          p = plot_clusters_waveforms(C.sh, C.sh_mean, cols, ctp, C.sweep_count, C.shape_correlation);
        case 3
          p = plot_clusters_psth_all(C.psth, C.sve, cols, ctp);
        case 4
          p = plot_clusters_isi(C.isis, cols, ctp);
        case 5
          p = plot_clusters_time_changes(C.sweep_count, cols, ctp);
        case 6
          p = plot_clusters_trigger(C.trigger, cols, ctp, n);
        case 7
          p = plot_clusters_fsp_separation(C.fsp, cols, ctp);
        case 8
          p = plot_clusters_ccg(C.data, C.acgs, cols, ctp);
        case 9
          p2 = plot_clusters_waveforms(C.sh, C.sh_mean, cols, ctp, C.sweep_count, C.shape_correlation);
          p3 = plot_clusters_psth_all(C.psth, C.sve, cols, ctp);
          p4 = plot_clusters_isi(C.isis, cols, ctp);
          p5 = plot_clusters_time_changes(C.sweep_count, cols, ctp);
          p6 = plot_clusters_trigger(C.trigger, cols, ctp, n);
      end
      
    case 'P' % special plots
      switch todo{2}
        case '1'
          plot_STRFs_ctuning_drc(C.data);
        case '2'
          plot_STRFs_CRF04(C.data);
        case '3'
          plot_STRFs_natural_contrast(C.data);
      end
      
    case 'm' % merge
      C_backup = C;
      C = cluster_merge(C, cell2mat(todo(2:end)));
      
    case 'd' % delete
      C_backup = C;
      C = cluster_delete(C, todo{2});
      
    case 'c' % cleave
      C_backup = C;
      C = cluster_cleave(C, todo{2}, todo{3}, todo{4}, dirs);
      
    case 'C' % cleave out
      C_backup = C;
      C = cluster_cleave_out(C, todo{2}, todo{3}, todo{4}, dirs);

    case 'i' % fix ISIs < 1ms
      C_backup = C;
      C = cluster_fix_isis_1ms(C, todo{2}, dirs, cols);
      
    case 'I' % fix ISIs ~ 50Hz
      C_backup = C;
      [C n_harmonics] = cluster_fix_isis_50Hz_2(C, todo{2}, dirs, cols);
      if n_harmonics > 0
        history = update_history(history(1:end-1), [todo n_harmonics], dirs);
      end
      
    case 'J' % fix ISIs ~ 100Hz
      C_backup = C;
      [C n_harmonics] = cluster_fix_isis_100Hz_2(C, todo{2}, dirs, cols);
      if n_harmonics > 0
        history = update_history(history(1:end-1), [todo n_harmonics], dirs);
      end
        
    case 's' % save
      C_backup = C;
      C = cluster_save(C, todo{2}, dirs);
      
    case 'S' % save all
      C_backup = C;
      C = cluster_save(C, 1:n.c, dirs);
      continue_loop = false;
      
    case 'u' % undo
      C = C_backup;
      history = history(1:end-1);
      
    case '!' % start over again
      fprintf('\nHistory of what you did:\n');
      display_history(history);
      pause(2); pause;
      C = C_init;
      
    case 'h' % view history
      fprintf('\nHistory of what you did:\n');
      display_history(history);
      pause(2); pause;      
      
    case 'H' % repeat history
      dirs.cluster_dest = [dirs.root 'clusters.' datestr(now, 'yyyy-mm-dd.HHMM') filesep];
      mkdir_nowarning(dirs.cluster_dest);
      C = cluster_repeat_history(C_init, todo{2}, dirs, cols);
      history = update_history(todo{2}, {'h'}, dirs);
      
    case 'k' % keyboard mode
      fprintf_subtitle('keyboard mode. type ''return'' to continue');
      keyboard;
      
    case 'Q' % quit
      continue_loop = false;
  end
end
    
fprintf_title(['clusters saved in: ' escape_slash(dirs.cluster_dest)]);
