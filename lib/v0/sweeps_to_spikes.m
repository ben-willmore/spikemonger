function spikes = sweeps_to_spikes(sweeps)
  % spikes = sweeps_to_spikes(sweeps)
  %
  % Simple function for converting sweeps to spikes!
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)


  fields.all = fieldnames(sweeps);
  fields.tocopy = {};
  for ii=1:L(fields.all)
    try
      if strcmp(fields.all{ii}(1:6),'spike_')
        fields.tocopy = [fields.tocopy fields.all(ii)];
      end
    catch
    end
  end

  spikes = struct;
  for ii=1:L(fields.tocopy)    
    try
      spikes.(fields.tocopy{ii}(7:end)) = [sweeps.(fields.tocopy{ii})];
    catch
      keyboard;
    end
  end

end