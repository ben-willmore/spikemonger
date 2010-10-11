function swl = get_sweep_list(dirs)
  % swl = get_sweep_list(dirs)
  
  % sweep timestamps
  ts = dir([dirs.sweeps '20*']);
  
  % map files inside each sweep
  swl = struct;
  for ii=1:L(ts)
    swl(ii).timestamp = ts(ii).name;
    
    % all files 
    f = getmatfilelist([dirs.sweeps swl(ii).timestamp '/']);
    for jj=1:L(f)
      fn = f(jj).name;
      f(jj).type = get_prefix(fn);      
      f(jj).bwvt_source = strip_prefix(strip_suffix(fn));
      f(jj).timestamp = swl(ii).timestamp;
    end
    f = rmfield(f, {'bytes','isdir','datenum','date'});
    swl(ii).all_files = f;
    
    % files by type
    [types junk type_idx] = unique({f.type});
    by_type = struct;
    for jj=1:L(types)
      t = types{jj};
      by_type.(t) = f(type_idx==jj);
    end
    swl(ii).by_type = by_type;
        
  end
  
%end