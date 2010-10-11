function c = t3_v(t,v)
  % T3_V
  %   c = t3_v(t,v)
  %
  % quick tensor multiplication, where:
  %   -  size(t)  = [s1 x s2 x s3]
  %   -  size(v)  = [s3 x 1]
  % yielding c, where
  %   -  size(c)  = [s1 x s2]
  
  [s1 s2 s3] = size(t);

  c = reshape( t,  s1*s2, s3 );
  c = c * v;
  c = reshape( c,  s1,    s2 );
  
end