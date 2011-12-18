function [sweep_params swl] = check_sweep_consistency(dirs,swl)
  % check_sweep_consistency(dirs)
  % check_sweep_consistency(dirs,swl)

  
fprintf('\nchecking consistency of sweeps across channels:\n');

%% get the list of sweeps
% ------------------------

if nargin<2
  fprintf_bullet('compiling sweep list...',1);
  if does_log_exist(dirs,'A1.swl.generated');
    swl = get_event_file(dirs,'sweep_list');
  else
    swl = get_sweep_list(dirs);
    save_event_file(dirs,swl,'sweep_list');
    create_log(dirs,'A1.swl.generated');
  end
  fprintf('[ok]\n');
end

%% same number of channels per sweep
% -----------------------------------

% how many in each
fprintf_bullet('checking number of channels per sweep...');
n.sweeps = L(swl);
n.sweep_params = nan(1,L(swl));
for ii=1:n.sweeps
  swpf = swl(ii).by_type.sweep_params;
  n.sweep_param_files(ii) = L(setdiff({swpf.name},'sweep_params.mat'));
end

tokeep = true(1,L(swl));

% are they all the same
if ~(L(unique(n.sweep_param_files))==1)  
  fprintf('different number of channels per sweep. fixing by deleting sweeps:\n');
  max_n_sweeps = max(n.sweep_param_files);
  tokeep = (n.sweep_param_files == max_n_sweeps);
  disp(find(~tokeep));
end
fprintf('[ok]\n');


%% same parameters for each sweep
% ----------------------------------

p = 0;
fprintf_bullet('checking sweep parameters');
all_sweep_params = cell(1,L(swl));

for ii=1:L(swl)
  p = print_progress(ii,L(swl),p);
  swpf = swl(ii).by_type.sweep_params;
  
  % skip if the aggregated file exists already
  %if does_sweep_file_exist(dirs,swpf(1).timestamp,'sweep_params')
  %  continue;
  %end
  
  % import sweep params
  swp = cell(1,L(swpf));
  for jj=1:L(swpf)
    swp{jj} = get_sweep_file(swpf(jj));
  end

  % check that the sweep parameter names are consistent
  try
    swp = cell2mat(swp);
  catch
    error('bwvt:error','different sweep parameter names across channels');
  end

  % check that the sweep parameter values are consistent
  if size(unique(reach(swp,'all.values''')','rows')',2)~=1    
    error('bwvt:error','different sweep parameter values across channels');
  end
  
  % check that the sweep lengths are consistent
  if L(unique([swp.length_signal_smp])) > 1
    fprintf('\n');
    fprintf_bullet(['timestamp ' swpf(1).timestamp ' corrupt: different signal lengths across channels. deleting.\n'],2);    
    fprintf('     ');
    tokeep(ii) = false;
  end  
  
  % put it into structure
  all_sweep_params{ii} = swp(1);
  all_sweep_params{ii}.timestamp = swpf(1).timestamp;
  
end

%% check sweep metadata consistency *across* sweeps
% ====================================================

% main metadata
ref_fieldnames = fieldnames(all_sweep_params{1});
all_the_same_fieldnames = all(cellfun(@(x) isequal(fieldnames(x), ref_fieldnames), all_sweep_params));
if ~all_the_same_fieldnames
   % get a list of all the necessary fieldnames
   fields = {};
   for ii=1:L(all_sweep_params)
       fields = [fields; fieldnames(all_sweep_params{ii})];
   end
   fields = setdiff(unique(fields), {'all', 'timestamp', 'length_signal_ms', 'length_signal_smp'});
   fields = sort(fields);
   % run through each inidividual entry in all_sweep_params and add the
   % missing fields
   for ii=1:L(all_sweep_params)
       for jj=1:L(fields)
           field = fields{jj};
           % try retrieve the field
          try
             all_sweep_params{ii}.(field);
           % if it doesnt exist
          catch
              all_sweep_params{ii}.(field) = -1;
          end
       end
      % sort field names
      all_sweep_params{ii} = orderfields(all_sweep_params{ii});
   end
   % reconstruct the main.all metadata
   for ii=1:L(all_sweep_params)
     all_sweep_params{ii}.all.names = fields';
     all_sweep_params{ii}.all.values = cellfun(@(x) all_sweep_params{ii}.(x), fields)';
   end
end

%% finish up
% ============

% delete erroneous sweeps
for ii=find(~tokeep)
  rmdir([dirs.sweeps swl(ii).timestamp '/'], 's');
end
  
% aggregate
try
  sweep_params = cell2mat(all_sweep_params(tokeep));

catch
  % which sweep params belong to which group
  [junk, idx, gp] = unique(cellfunc(@(x) cell2mat(x.all.names), all_sweep_params)');
  % the full list of names
  names = {};
  for ii=1:L(idx)
    names = [names all_sweep_params{idx(ii)}.all.names];
  end
  names = unique(names);
  % add -1s to those unavailable
  for ii=1:L(all_sweep_params)
    for jj=1:L(names)
      name = names{jj};
      try
	all_sweep_params{ii}.(name);
      catch
	all_sweep_params{ii}.(name) = -1;
      end
    end
  end
  % add data to the 'all' field
  for ii=1:L(all_sweep_params)
    all_sweep_params{ii}.all.names = names;
    all_sweep_params{ii}.all.values = ...
        cellfun(@(x) all_sweep_params{ii}.(x), names);
  end
  % sort the fields
  for ii=1:L(all_sweep_params)
    all_sweep_params{ii} = orderfields(all_sweep_params{ii});
  end
  % now try it
  sweep_params = cell2mat(all_sweep_params(tokeep));
  
end


swl = swl(tokeep);

% save it
save_event_file(dirs,sweep_params,'sweep_params');
save_event_file(dirs,swl,'sweep_list');
fprintf('[ok]\n');