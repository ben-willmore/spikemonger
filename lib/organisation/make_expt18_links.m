% sources
dirs.source_root = '/shub/experiments/data.expt18/raw.all/';
dirs.source = dir([dirs.source_root 'P*']);
for ii=1:L(dirs.source)
  dirs.source(ii).fullname = [dirs.source_root dirs.source(ii).name '/'];
end

dirs.dest_root = '/shub/experiments/data.expt18/raw.sorted/';

% source and destination names
for pp=1:L(dirs.source)
  batches = dir([dirs.source(pp).fullname '*28.bwvt']);
  for ii=1:L(batches)
    n = batches(ii).name;
    n = n(1:(strfind(n,'G_RZ5')-2));
    batches(ii).prefix = n;
    n(strfind(n,'-'))='.';
    batches(ii).dest = n;
  end
  disp({batches.dest}');
  dirs.source(pp).batches = batches;
end

%% create links
% ===============

for pp=1:L(dirs.source)
  for ii=1:L(dirs.source(pp).batches)
    s = dirs.source(pp);
    b = dirs.source(pp).batches(ii);
    files = dir([s.fullname b.prefix '-G_RZ*.bwvt']);
    for ff=1:L(files)
      files(ff).num = str2double(files(ff).name((end-6):(end-5)));
      files(ff).fullname = [s.fullname files(ff).name];
    end
    
    destdir.L = [dirs.dest_root b.dest '.L/'];
    destdir.R = [dirs.dest_root b.dest '.R/'];
    mkdir_nowarning(destdir.L);
    mkdir_nowarning(destdir.R);
    
    for ff=1:L(files)
      if files(ff).num<=16
        system(['ln -s ' files(ff).fullname ' ' destdir.L files(ff).name]);
      else
        system(['ln -s ' files(ff).fullname ' ' destdir.R files(ff).name]);
      end
    end
  end
end