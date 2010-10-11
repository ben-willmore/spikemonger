function sweeps = spikes_to_sweeps(spikes, sweeps)
  % sweeps = spikes_to_sweeps(spikes, sweeps)
  %
  % Simple function for converting spikes to sweeps!
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)
  

% remove anything in sweeps starting with 'spike'
  fns = fieldnames(sweeps);
  toremove = false(1,L(fns));
  for ii=1:L(fns)
    toremove(ii) = ~isempty(strfind(fns{ii},'spike'));
  end
  sweeps = rmfield(sweeps,fns(toremove));
  
% fields to copy
  fields.sweeps = fieldnames(spikes);
  fields.spikes = fieldnames(spikes);
  for ii=1:L(fields.sweeps)
    fields.sweeps{ii} = ['spike_' fields.sweeps{ii}];
    sweeps(1).(fields.sweeps{ii}) = [];
  end
  
% transfer data
  sweep_ids = unique(spikes.sweep_id);  
  for hh=sweep_ids
    sweeps(hh).sweep_id = hh;    
    for ii=1:L(fields.sweeps)
      sweeps(hh).(fields.sweeps{ii}) = spikes.(fields.spikes{ii})(:,(spikes.sweep_id==hh));
    end
  end
  
    



end