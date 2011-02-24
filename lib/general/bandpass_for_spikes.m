function signal = bandpass_for_spikes(signal,fs)
  % signal = bandpass_for_spikes(signal)
  
  % acausal filtering of signal for spike detection
  % using 0.3-3kHz passband

  % construct filter
  Wp = [300 3000];
  n = 4;
  [z,p,k] = ellip(n, 1, 40, Wp/(fs/2));
  [sos,g] = zp2sos(z,p,k);
  Hd = dfilt.df2tsos(sos,g);
  
  % filter
  signal = filtfilthd(Hd,signal);