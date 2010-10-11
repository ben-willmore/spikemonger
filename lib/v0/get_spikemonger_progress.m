function progress = get_spikemonger_progress(root_directory)
  % progress = get_spikemonger_progress(root_directory)
  %
  % interim function for determining how much spikemongering has been done
  % on a particular set of .src files (identified by their root directory)
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
  dirs.root = fixpath(root_directory);
  
  % check that directory exists
    if L(dir(dirs.root)) == 0
      error('directory:error','directory does not exist');
    end
    
  % how many src files are there in the root directory
    n.srcs = L(dir([dirs.root '*.src']));
    n.bwvts = L(dir([dirs.root '*.bwvt']));
    if n.srcs + n.bwvts == 0
      error('directory:error','no .src files or .bwvt files found in root directory');
    end
    
  % stage 1
    progress = 0;
    if L(dir([dirs.root 'stage_1_converted_srcs/*.mat'])) < max(n.srcs,n.bwvts);
      return;
    end
    
  % stage 2
    progress = 1;
    if L(dir([dirs.root 'stage_2_removed_artefacts/*.mat'])) < max(n.srcs,n.bwvts);
      return;
    end    
    
  % stage 3
    progress = 2;
    

end
    