function progress = get_spikemonger_progress(dirs)
  % progress = get_spikemonger_progress(dirs)
  % progress = get_spikemonger_progress(root_directory)
  %
  % interim function for determining how much spikemongering has been done
  % on a particular set of .src files (identified by their root directory)
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
  dirs = fix_dirs_struct(dirs);
  
  % progress structure
  progress = struct;
  progress.directory_exists = false;
  progress.n_src = 0;
  progress.n_bwvt = 0;
  progress.has_src = false;
  progress.has_bwvt = false;
  progress.has_raw_files = false;  
  progress.converted_src_files = false;
  progress.converted_bwvt_files = false;
  progress.converted_raw_files = false;  
  progress.clustered = false;
  progress.clustered_time = false;
  progress.clustered_no_time = false;
  
  % does the directory exists
  if L(dir(dirs.root)) == 0
    return;
  end
  
  % how many src/bwvt files are there in the root directory
  n.src  = L(dir([dirs.root '*.src']));
  n.bwvt = L(dir([dirs.root '*.bwvt']));
  progress.n_src = n.src;
  progress.n_bwvt = n.bwvt;
  progress.has_src = n.src > 0;
  progress.has_bwvt = n.bwvt > 0;
  progress.has_raw_files = (n.src + n.bwvt) > 0;
  
  % if there are no raw files, end here
  if ~progress.has_raw_files 
    return;
  end
  
  % if the bwvt files have been converted already
  if L(dir([dirs.logs 'A1.finished.log'])) == 0
    return;
  end
  progress.converted_raw_files = true;
  if n.src==0, progress.converted_bwvt_files = true; end
  
  % have the clusters been created
  if ~(L(dir([dirs.events 'candidates.mat']))==1) | ...
     ~(L(dir([dirs.events 'feature_space.mat']))==1)
    return;
  end
  if L(dir([dirs.events 'clusters_time.mat']))==1
    progress.clustered_time = true;
  end
  if L(dir([dirs.events 'clusters_no_time.mat']))==1
    progress.clustered_no_time = true;
  end
  if ~(progress.clustered_no_time | progress.clustered_time)
    return;
  end
  progress.clustered = true;