function c = t3_v_v(t,v2,v3)
  % T3_V_V
  %   c = t3_v_v(t,v1,v2)
  %
  % quick tensor multiplication, where:
  %   -  size(t)  = [s1 x s2 x s3]
  %   -  size(v2) = [s2 x 1]
  %   -  size(v3) = [s3 x 1]
  % yielding c, where
  %   -  size(c)  = [s1 x 1]
  
  [s1 s2 s3] = size(t);

  c = reshape( t,  s1*s2, s3 );
  c = c * v3;
  c = reshape( c,  s1,    s2 );
  c = c * v2;
  
end