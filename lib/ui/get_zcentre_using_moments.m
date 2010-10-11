function [z_mean z_std] = get_zcentre_using_moments(z,varargin)
  % [zc bw] = get_zcentre_using_moments(w)

  % angles
  th = (1:L(z))'/L(z) * 2 * pi;  
  
  % mean
  th2 = circ_mean(th,z.^2);
  if th2<0, th2=th2+2*pi; end
  z_mean = th2/(2*pi)*L(z);
  
  % std
  th3 = circ_std(th,z.^2);
  if th3<0, th3=th3+2*pi; end
  z_std = th3/(2*pi)*L(z);
