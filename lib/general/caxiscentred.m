function caxiscentred(n,ax)
  % caxiscentred
  %   - centres the caxis scale around 0
  %   - uses abs(max(data(:)))*[-1 1] as the scale
  %
  % caxiscentred(n)
  %   - as above, except scaled
  %   - uses abs(max(data(:)))*[-1 1]/n as the scale
  
  if nargin==0
    n = 1;
  end
    
  cax = max(abs(pick(get(get(gca,'children'),'cdata'),':')))*[-1 1]/n;
  
  if nargin<=1
    caxis(cax);
  elseif nargin==2
    set(ax,'clim',cax);
  end
  
end