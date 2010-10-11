function histtest(data)

  spikes = data.spikes;  
  peakmax = max(abs(data.spikes.shapes));
  t = data.spikes.t_insweep_ms;
  cols = hsv;
  cutoffs = [30 40 50 60 70];
  
  figure(20);
  clf;
  hold on;
  for ii=1:5
    cutoff = cutoffs(ii);
    col = cols(1+mod(10*(ii-1),64),:);
    area(0:10:1000,histc(t(peakmax > cutoff),0:10:1000),'facecolor',col);
  end
  
  xlim([0 1000]);
  legend(...
    {num2str(cutoffs(1)),num2str(cutoffs(2)),num2str(cutoffs(3)),num2str(cutoffs(4)),num2str(cutoffs(5))},...
    'fontweight','bold','fontsize',16);
  
  pause;
  close(20);
  
end