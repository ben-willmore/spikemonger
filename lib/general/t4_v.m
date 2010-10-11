function c = t4_v(t,v)
  % T4_V
  %   c = t4_v(t,v)
  %
  % quick tensor multiplication, where:
  %   -  size(t)  = [s1 x s2 x s3 x s4]
  %   -  size(v) = [s4 x 1]
  % yielding c, where
  %   -  size(c)  = [s1 x s2 x s3]
  
  [s1 s2 s3 s4] = size(t);

  c = reshape( t,  s1*s2*s3, s4 );
  size(c), size(v)
  c = c * v;
  c = reshape( c,  [s1, s2, s3] );
  
end