function tt = T(signal,fs)
  % T
  %  tt = T(signal,fs)
  %
  % creates a time axis based on a signal and its sample rate (fs) for
  % plotting.
  
  if L(signal)==1
    tt = (1:signal)/fs;
  else
    tt = (1:L(signal))/fs;
  end
  
end