function plot_contrast_analysis(data)

  
%% prelims
% =========

GRIDDIR = '/data/contrast/tokens/v7.grids/';


ks = cell(1,L(data));
fprintf_bullet('calculating kernels',2); t1 = clock; p=0;
for aa=1:L(data)

  p = print_progress(aa,L(data),p);
  datat = data(aa).set;
  
  % load grids
  dirs.grid = GRIDDIR;  
  for ii=1:L(datat)
    
    contrast = datat(ii).stim_params.Fullwidth;
    level = datat(ii).stim_params.Level_dB_SPL;
    token_num = datat(ii).stim_params.Token;
    
    datat(ii).contrast = contrast;
    datat(ii).level = level;
    datat(ii).token_num = token_num;
    
    % load grid
      fn = [dirs.grid 'grid.contrast.fullwidth.' n2s(contrast) '.token.' n2s(token_num) '.mat'];
      tok = load(fn);
      datat(ii).grid = tok.grid;
      
      % centre each
      datat(ii).grid = datat(ii).grid.naive - mean(datat(ii).grid.naive(:));
  end
  


% prepare input datat
% --------------------

% histogram
tt = (0.1:0.025:15.1)*1000;
for ii=1:L(datat)
  t = datat(ii).spikes.t;
  h = droptail(histc(t,tt));
  h = h / L(datat(ii).repeats);
  datat(ii).h = h;
end

dt2 = struct;
dt2.repeats = [datat.repeats];
sve = sahani_variance_explainable(datat,tt(81:600));

% metadata
for ii=1:L(datat)
  datat(ii).tokeep = false(1,600);
  datat(ii).tokeep(81:548) = true;
  
  datat(ii).tokeep_prediction = false(1,600);
  datat(ii).tokeep_prediction(549:600) = true;
  
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
  figh = 400;
else
  n.cols = L(data);
  n.rows = 1;
  figw = 1600;
  figh = 400;
end


% plot
figure; clf; set_fig_size(figw, figh);

for ii=1:L(ks)
  
  % retrieve data
  w = ks(ii).w.ff_by_tt;
  
  % plot
  ax(n.rows,n.cols,ii);
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
  sp = ks(ii).sve.signal_power / ks(ii).sve.total_power;
  sp = round(sp*1000)/10;
  pve = round(ks(ii).prediction_test.prop_ve_sahani * 100);
  if sp > 0
    if pve > 0
      title10bf({[n2s(sp) '% SP'], [n2s(pve) '% SPE']});
    else
      title10bf([n2s(sp) '% SP']);
    end
  end
  
  xlabel14bf(['C ' n2s(ii)]);
  
end
  
