function gps = groupify(d,gp_1_min,gp_end_max,ngps)

  mind = gp_1_min;
  maxd = gp_end_max;
  
  gpi = droptail( linspace(mind,maxd,ngps+1) );
  gpf = drophead( linspace(mind,maxd,ngps+1) );
  
  d = d(:)';
  gps = false(ngps,L(d));
  for ii=1:(ngps-1)
    gps(ii,:) = (d>=gpi(ii))&(d<gpf(ii));
  end
  gps(end,:) = (d>=gpi(end))&(d<=gpf(end));
  
end