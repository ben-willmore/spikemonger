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
dirs.raw_bwvt = [dirs.root 'raw.bwvt' filesep];
dirs.raw_f32 = [dirs.root 'raw.f32' filesep];
dirs.regressed_f32 = [dirs.root 'regressed.f32' filesep];
dirs.sweeps = [dirs.root 'sweeps' filesep];
dirs.events = [dirs.root 'events' filesep];
dirs.logs = [dirs.root 'logs' filesep];

%mkdir_nowarning(dirs.sweeps);
mkdir_nowarning(dirs.events);
mkdir_nowarning(dirs.logs);