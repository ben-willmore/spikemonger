function plot_STRFs_natural_contrast(data)


%% prelims
% =========

compname = get_current_computer_name;
switch compname
  case 'macgyver'
    dirs.grid = '/shub/drc/stimuli.ctuning/tokens.grids';
  otherwise
    fprintf('you need to enter into plot_contrast_analysis.m the location of the grid files\n');
    keyboard;
end

% kernels structure
ks = cell(1, L(data));

% run through all clusters
fprintf_bullet('calculating kernels', 2); t1 = clock; p=0;
for aa=1:L(data)
  p = print_progress(aa, L(data), p);  
  
  % just the DRC parts
  datat = data(aa).set;
  try
    datat = datat(reach(datat, 'stim_params.Source') == 1);
  catch
  end
  
  % load grids
  for ii=1:L(datat)
    fw = datat(ii).stim_params.Fullwidth;
    token = datat(ii).stim_params.Token;
    level = datat(ii).stim_params.Level;
    frozen = datat(ii).stim_params.Frozen;
    
    datat(ii).fw = fw;
    datat(ii).token = token;
    datat(ii).frozen = frozen;
    datat(ii).level = level;
    
    % load grid
    fn = sprintf('%s/grid.ctuning.ongoing.fw.%d.token.%d.frozen.%d.mat', ...
      dirs.grid, fw, token, frozen);
    grid = load(fn);
    datat(ii).grid = grid.grid - mean(grid.grid(:));
  end
  
  
  % prepare input datat
  % --------------------
  
  % histogram
  tt = (0:0.025:5)*1000 + 10;
  n.blocks = 200;
  tokeep_num = 41:180;
  tokeep_prediction_num = 181:199;
  

  for ii=1:L(datat)
    t = datat(ii).spikes.t;
    h = droptail(histc(t, tt));
    h = h / L(datat(ii).repeats);
    if L(h) == 0
      h = 0 * tt;
    end
    datat(ii).h = h;
  end
  
  dt2 = struct;
  dt2.repeats = [datat.repeats];
  sve = sahani_variance_explainable(datat, tt(tokeep_num));
  
  % metadata
  for ii=1:L(datat)
    datat(ii).tokeep = false(1, n.blocks);
    datat(ii).tokeep(tokeep_num) = true;
    
    datat(ii).tokeep_prediction = false(1, n.blocks);
    datat(ii).tokeep_prediction(tokeep_num) = true;
        
  end
  
  % aggregate
  dd = 1:L(datat);
  grid = [datat(dd).grid];
  sph  = [datat(dd).h];
  tk   = [datat(dd).tokeep];
  tkp  = [datat(dd).tokeep_prediction];
  
  params.time_bins_to_keep = tk;
  params.n.tt = 10;
  
  params_prediction = params;
  params_prediction.time_bins_to_keep = tkp;
  
  
  % get RF for all together
  % --------------------------
  
  % kernel
  %keyboard;
  k = get_kernel_ml_ff_tt(grid, sph, params);
  k.training_test = test_kernel_ff_tt(k, grid, sph, params);
  k.prediction_test = test_kernel_ff_tt(k, grid, sph, params_prediction);
  
  % sahani variance explained
  k.training_test.sahani = sve;
  k.training_test.prop_ve_sahani  = k.training_test.prop_ve  * sve.scale_performance_factor;
  k.training_test.prop_ves_sahani = k.training_test.prop_ves * sve.scale_performance_factor;
  k.prediction_test.sahani = sve;
  k.prediction_test.prop_ve_sahani  = k.prediction_test.prop_ve  * sve.scale_performance_factor;
  k.prediction_test.prop_ves_sahani = k.prediction_test.prop_ves * sve.scale_performance_factor;
  k.sve = sve;
  
  ks{aa} = k;
end

ks = cell2mat(ks);
fprintf_timediff(t1);

%% display
% ==========

% graph size
if L(data)<=8
  n.rows = 1;
  n.cols = 8;
  figw = 1000;
  figh = 600;
else
  n.cols = L(data);
  n.rows = 1;
  figw = 1600;
  figh = 600;
end

% plot
figure; clf; set_fig_size(figw, figh);

for ii=1:size(ks, 2)
  try
    % retrieve data
    w = ks(ii).w.ff_by_tt;
    
    % plot
    ax(n.rows, n.cols, 1, ii);
    imagesc(w);
    
    % aesthetics
    noticklabels;
    caxiscentred;
    freqs = 2 .^( log2(0.5e3) : 1/6 : log2(24e3) );
    yt = round(linspace(1, 34, 6));
    ytl = round(freqs(yt)/100)/10;
    set(gca, 'ytick', yt);
    if ii==1
      set(gca, 'yticklabel', ytl);
    end
    
    % title
    sp = ks(ii).sve.signal_power / ks(ii).sve.total_power;
    sp = round(sp*1000)/10;
    pve = round(ks(ii).prediction_test.prop_ve * 100);
    if sp > 0
      if pve > 0
        title10bf({[n2s(sp) '% SP'], [n2s(pve) '% PVE']});
      else
        title10bf([n2s(sp) '% SP']);
      end
    end
    
    xlabel14bf(['C ' n2s(ii)]);
    
  catch
  end
end

end

