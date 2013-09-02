function files = getfilelist(sourcedir,ext,varargin)
  % files = getfilelist(sourcedir,ext)
  % files = getfilelist(sourcedir,ext,'prefix')
  
  files = dir([sourcedir '*.' ext]);
  if nargin==3
    files = dir([sourcedir ext '*']);
  end
  
  % hackily add prefix and fullname fields so that the output is compatible 
  % even if empty
  tmp=cell(size(files));
  [files(:).prefix]=deal(tmp{:});
  [files(:).fullname]=deal(tmp{:});

  for ii=1:L(files)
    files(ii).fullname = [sourcedir files(ii).name];
    files(ii).prefix   = strip_suffix(files(ii).name);
  end
  
