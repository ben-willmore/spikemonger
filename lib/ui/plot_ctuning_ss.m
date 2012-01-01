% choose directory
%source_dir = '/data/contrast/tokens/ctuning.tokens.expt30/P12-ctuning.drc/stimuli.channel.10/grids/';
source_dir = '/data/contrast/tokens/ctuning.tokens.expt30/P10-ctuning.drc/stimuli.channel.25/grids/';

% get files
files = getmatfilelist(source_dir);
grids = cell(1, 10);
for ii=1:10
  g = load(files(ii).fullname);
  grids{ii} = g.token;
end
grids = cell2mat(grids);

% accumulate data
limiting_fw = 20;

for ii=1:L(C.data)
for jj=1:20
  spt = C.data(ii).set(jj).spikes.t;
  params = C.data(ii).set(jj).stim_params;

  ti = grids(params.Token).probe_start_time * 1000 - 50;
  tf = ti + 250;

  all_resp = cell2mat(cellfunc(@(kk) histc_nolast(spt, ti(kk):5:tf(kk)), find(grids(params.Token).probe_fw >= limiting_fw))');
  C.data(ii).set(jj).all_resp = all_resp;
  C.data(ii).set(jj).mean_resp = mean(all_resp);
end
end

for ii=1:L(C.data)
  C.data(ii).mean_resp_embedded = mean(reach(C.data(ii).set(reach(C.data(ii).set, 'stim_params.Embedded')==1), 'mean_resp''')');
  C.data(ii).mean_resp_silence = mean(reach(C.data(ii).set(reach(C.data(ii).set, 'stim_params.Embedded')==0), 'mean_resp''')');
  C.data(ii).bg_embedded = mean(C.data(ii).mean_resp_embedded(1:10));
  C.data(ii).bg_silence = mean(C.data(ii).mean_resp_silence(1:10));
  
  [SP, NP, TP] = sahani_quick(reach(C.data(ii).set(reach(C.data(ii).set, 'stim_params.Embedded')==0), 'all_resp''')');
  C.data(ii).SP_silence = round(SP/TP * 1000) / 10;
  [SP, NP, TP] = sahani_quick(reach(C.data(ii).set(reach(C.data(ii).set, 'stim_params.Embedded')==1), 'all_resp''')');
  C.data(ii).SP_embedded = round(SP/TP * 1000) / 10;  
end
  


% plot
figure(10); clf; set(10, 'position', [800, 0, 400, 1000]);
for ii=1:L(C.data)
  ax(L(C.data), 1, ii);
  hold on;
  
  area(C.data(ii).mean_resp_silence, 'facecolor', cols(ii, :));
  plot([1, 50], C.data(ii).bg_silence * [1 1], 'k--', 'linewidth', 2);
  if ii<L(C.data)
    noticks;
  else
    set(gca, 'ytick', [], 'xtick', linspace(1, 50, 7)+0.5, 'xticklabel', linspace(-50, 250, 7));
  end
  yl = ylim;
  plot([10 10]-0.5, yl, 'k');
  title10bf([n2s(C.data(ii).SP_silence) ' % SP']);
end

figure(11); clf; set(11, 'position', [1200, 0, 400, 1000]);
for ii=1:L(C.data)
  ax(L(C.data), 1, ii);
  hold on;
  
  area(C.data(ii).mean_resp_embedded, 'facecolor', cols(ii, :));
  plot([1, 50], C.data(ii).bg_embedded * [1 1], 'k--', 'linewidth', 2);
  if ii<L(C.data)
    noticks;
  else
    set(gca, 'ytick', [], 'xtick', linspace(1, 50, 7)+0.5, 'xticklabel', linspace(-50, 250, 7));
  end
  yl = ylim;
  plot([10 10]-0.5, yl, 'k');
  title10bf([n2s(C.data(ii).SP_embedded) ' % SP']);
end