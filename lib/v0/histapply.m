function data = histapply(data,threshold)
  
  peakmax = max(abs(data.spikes.shapes));
  t = data.spikes.t_insweep_ms;
  tokeep = (peakmax >= threshold);
  
  fields = fieldnames(data.spikes);
  for ii=1:L(fields)
    data.spikes.(fields{ii}) = data.spikes.(fields{ii})(:,tokeep);
  end
  
  for cc=1:L(data.cluster)
    peakmax = max(abs(data.cluster(cc).spikes.shapes));
    t = data.cluster(cc).spikes.t_insweep_ms;
    tokeep = (peakmax >= threshold);

    fields = fieldnames(data.cluster(cc).spikes);
    for ii=1:L(fields)
      data.cluster(cc).spikes.(fields{ii}) = data.cluster(cc).spikes.(fields{ii})(:,tokeep);
    end
    
  
  
  
end