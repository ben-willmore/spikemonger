function files = getfilelist(sourcedir,ext,varargin)
  % files = getfilelist(sourcedir,ext)
  % files = getfilelist(sourcedir,ext,'prefix')
  
  files = dir([sourcedir '*.' ext]);
  if nargin==3
    files = dir([sourcedir ext '*']);
  end
  
  for ii=1:L(files)
    files(ii).fullname = [sourcedir files(ii).name];
    files(ii).prefix   = strip_suffix(files(ii).name);
  end
  
