function plot_contrast_analysis_2(data)

  
%% prelims
% =========

compname = get_current_computer_name;
switch compname
  case 'macgyver'
    GRIDDIR2 = '/data/contrast/tokens/frozen.grids/';
    GRIDDIR7 = '/data/contrast/tokens/v7.grids/';
  case 'chai'
    GRIDDIR2 = '/wocka/neil/contrast/tokens/frozen.grids/';
    GRIDDIR7 = '/wocka/neil/contrast/tokens/v7.grids/';
  otherwise
    fprintf('you need to enter into plot_contrast_analysis.m the location of the grid files\n');
    keyboard;
end


ks = cell(2,L(data));
fprintf_bullet('calculating kernels',2); t1 = clock; p=0;
for aa=1:L(data)
  p = print_progress(aa,L(data),p);
  for bb=1:2 % first data vs last data
    
    datat = data(aa).set;
    switch bb
      case 1
        datat = datat(round([datat.length_signal_ms])==3.1e4);
        v = 2;
        dirs.grid = GRIDDIR2;
      case 2
        datat = datat(round([datat.length_signal_ms])==1.53e4);
        v = 7;
        dirs.grid = GRIDDIR7;
    end
    
    % load grids    
    for ii=1:L(datat)
      switch v
        case 2
          contrast = datat(ii).stim_params.Fullwidth;
        case 7
          contrast = datat(ii).stim_params.Fullwidth;
      end
      level = datat(ii).stim_params.Level_dB_SPL;
      token_num = datat(ii).stim_params.Token;
      
      datat(ii).contrast = contrast;
      datat(ii).level = level;
      datat(ii).token_num = token_num;
      
      % load grid
      switch v
        case 2
          fn = [dirs.grid 'grid.contrast.' n2s(contrast) '.token.' n2s(token_num) '.mat'];
        case 7
          fn = [dirs.grid 'grid.contrast.fullwidth.' n2s(contrast) '.token.' n2s(token_num) '.mat'];
      end
      
      tok = load(fn);
      datat(ii).grid = tok.grid;
      
      % centre each
      datat(ii).grid = datat(ii).grid.naive - mean(datat(ii).grid.naive(:));
    end
    
    
    
    % prepare input datat
    % --------------------
    
    % histogram
    switch v
      case 2
        tt = (0.5:0.025:30.5)*1000;
        n.blocks = 1200;
        tokeep_num = 81:1088;
        tokeep_prediction_num = 1089:1200;
      case 7
        tt = (0.1:0.025:15.1)*1000;
        n.blocks = 600;
        tokeep_num = 81:548;
        tokeep_prediction_num = 549:600;
    end
    
    for ii=1:L(datat)
      t = datat(ii).spikes.t;
      h = droptail(histc(t,tt));
      h = h / L(datat(ii).repeats);
      datat(ii).h = h;
    end
    
    dt2 = struct;
    dt2.repeats = [datat.repeats];
    sve = sahani_variance_explainable(datat,tt(tokeep_num));
    
    % metadata
    for ii=1:L(datat)
      datat(ii).tokeep = false(1,n.blocks);
      datat(ii).tokeep(tokeep_num) = true;
      
      datat(ii).tokeep_prediction = false(1,n.blocks);
      datat(ii).tokeep_prediction(tokeep_num) = true;
      
      datat(ii).contrasts = 0*datat(ii).tokeep + datat(ii).contrast;
      datat(ii).levels = 0*datat(ii).tokeep + datat(ii).level;
      
    end
    
    % aggregate
    dd = 1:L(datat);
    grid = [datat(dd).grid];
    sph  = [datat(dd).h];
    tk   = [datat(dd).tokeep];
    tkp  = [datat(dd).tokeep_prediction];
    
    params.time_bins_to_keep = tk;
    params.n.tt = 10;
    params.contrasts = [datat(dd).contrasts];
    params.levels = [datat(dd).levels];
    
    params_prediction = params;
    params_prediction.time_bins_to_keep = tkp;
    
    
    % get RF for all together
    % --------------------------
    
    % kernel
    k = get_kernel_ml_ff_tt(grid, sph, params);
    k.training_test = test_kernel_ff_tt(k,grid,sph,params);
    k.prediction_test = test_kernel_ff_tt(k,grid,sph,params_prediction);
    
    % sahani variance explained
    k.training_test.sahani = sve;
    k.training_test.prop_ve_sahani  = k.training_test.prop_ve  * sve.scale_performance_factor;
    k.training_test.prop_ves_sahani = k.training_test.prop_ves * sve.scale_performance_factor;
    k.prediction_test.sahani = sve;
    k.prediction_test.prop_ve_sahani  = k.prediction_test.prop_ve  * sve.scale_performance_factor;
    k.prediction_test.prop_ves_sahani = k.prediction_test.prop_ves * sve.scale_performance_factor;
    k.sve = sve;
    
    ks{bb,aa} = k;
  end
end

ks = cell2mat(ks);
fprintf_timediff(t1);

%% display
% ==========

% graph size
if L(data)<=8
  n.rows = 2;
  n.cols = 8;
  figw = 1000;
  figh = 600;
else
  n.cols = L(data);
  n.rows = 2;
  figw = 1600;
  figh = 600;
end


% plot
figure; clf; set_fig_size(figw, figh);

for ii=1:size(ks,2)
  for jj=1:2
    try
    % retrieve data
    w = ks(jj,ii).w.ff_by_tt;

    % plot
    ax(n.rows,n.cols,jj,ii);
    imagesc(w);

    % aesthetics
    noticklabels;
    caxiscentred;
    freqs = 2 .^( log2(0.5e3) : 1/6 : log2(24e3) );
    yt = round(linspace(1,34,6));
    ytl = round(freqs(yt)/100)/10;
    set(gca,'ytick',yt);
    if ii==1
      set(gca,'yticklabel',ytl);
    end

    % title
    sp = ks(jj,ii).sve.signal_power / ks(jj,ii).sve.total_power;
    sp = round(sp*1000)/10;
    pve = round(ks(jj,ii).prediction_test.prop_ve_sahani * 100);
    if sp > 0
      if pve > 0
        title10bf({[n2s(sp) '% SP'], [n2s(pve) '% SPE']});
      else
        title10bf([n2s(sp) '% SP']);
      end
    end

    if jj==2
      xlabel14bf(['C ' n2s(ii)]);
    end
    
    if ii==1 
      if jj==1
        ylabel14bf('v2');
      elseif jj==2
        ylabel14bf('v7');
      end
    end
    catch
    end
  end
  
end
  
