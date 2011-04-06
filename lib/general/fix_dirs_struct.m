function dirs = fix_dirs_struct(dirs)
  % dirs = fix_dirs_struct(dirs)

% check that it is a structure
if ~isstruct(dirs)
  root_dir = dirs;
  dirs = struct;
  dirs.root = root_dir;
end

% ensure there is a trailing slash
dirs.root = fixpath(dirs.root);
dirs.raw_bwvt = [dirs.root 'raw.bwvt/'];
dirs.sweeps = [dirs.root 'sweeps/'];
dirs.events = [dirs.root 'events/'];
dirs.logs = [dirs.root 'logs/'];

%mkdir_nowarning(dirs.sweeps);
mkdir_nowarning(dirs.events);
mkdir_nowarning(dirs.logs);