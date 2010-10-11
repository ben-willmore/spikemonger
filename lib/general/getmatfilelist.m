function files = getmatfilelist(sourcedir)
  files = dir([sourcedir '*.mat']);
  for ii=1:L(files)
    files(ii).fullname = [sourcedir files(ii).name];
  end
  
