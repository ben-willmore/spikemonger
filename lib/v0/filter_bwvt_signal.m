function signal = filter_bwvt_signal(signal,fs)

  % construct filter
    Wp = [300 3000];
    n = 6;
    [z,p,k] = ellip(n, 0.01, 80, Wp/(fs/2));
    [sos,g] = zp2sos(z,p,k);
    Hd = dfilt.df2tsos(sos,g);  

  % apply filter
    s1 = signal;
    s1 = filtfilthd(Hd,s1);

  % normalise
    s1 = (s1-mean(s1))/ std(s1);

end