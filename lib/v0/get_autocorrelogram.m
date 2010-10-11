function [tt acg isi] = get_autocorrelogram(spikes, dt)
  % [tt acg isi] = get_autocorrelogram(spikes, dt)
  %
  % Returns the autocorrelogram (acg), the interspike interval histogram
  % (isi), and the time (tt) for a spikes structure. 
  %
  % dt -- the size of the bins for the histograms.
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)



    sweep_ids = unique(spikes.sweep_id);
    n.sweeps = L(sweep_ids);
    
    sweeps = struct('isi',cell(1,max(sweep_ids)), 'acg',cell(1,max(sweep_ids)));

  % new method
    t = spikes.t_absolute_ms + 200*spikes.sweep_id;
    acg = [];
    for ii=2:200
      acgt = t(ii:end) - t(1:(end-ii+1));
      acgt = acgt(acgt > 0 & acgt < 100);
      acg = [acg acgt];
       if min(acgt) > 50
         break;
       end
    end
    isi = t(2:end) - t(1:(end-1));

  % construct histogram for output
    tt = 0:(dt):(100+dt/2);
    acg = histc(acg, tt);
    isi = histc(isi, tt);
    
  % only look at stuff before 50ms
    try
      acg = acg(tt <= 50);
      isi = isi(tt <= 50);
      tt  = tt(tt <= 50);
    catch
      tt  = tt(tt <= 50);
      acg = zeros(size(tt)); 
      isi = zeros(size(tt));
    end

end