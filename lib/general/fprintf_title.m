function fprintf_title(str,underline_length)
  % fprintf_title(str)
  % fprintf_title(str, underline_length)
  % 
  % prints str as follows:
  %
  % =====
  % str
  % =====
  
  if nargin==1
    underline_length = L(str)+2;
  end
  
  fprintf( ['\n' repmat('=',1,underline_length) '\n'] );
  fprintf( str );
  fprintf( ['\n' repmat('=',1,underline_length) '\n\n'] );