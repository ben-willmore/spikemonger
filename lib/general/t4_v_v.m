function c = t4_v_v(t,v1,v2)
  % T4_V_V
  %   c = t4_v_v(t,v1,v2)
  %
  % quick tensor multiplication, where:
  %   -  size(t)  = [s1 x s2 x s3 x s4]
  %   -  size(v1) = [s3 x 1]
  %   -  size(v2) = [s4 x 1]
  % yielding c, where
  %   -  size(c)  = [s1 x s2]
  
  [s1 s2 s3 s4] = size(t);

  c = reshape( t,  s1*s2*s3, s4 );
  c = c * v2;
  c = reshape( c,  s1*s2, s3 );
  c = c * v1;
  c = reshape( c, s1, s2 );
  
end