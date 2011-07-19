function spikemonger(rootdir, varargin)
% spikemonger(rootdir)

%% parse varargin
% ================

REGRESSED = false;

try
  if nargin>1
    if any(ismember({'regressed'}, varargin))
      REGRESSED = true;
    end  
  end
catch
end


%% initialise rootdir
% ======================

setpath;

if nargin==0
  rootdir = pwd;
end

% put into structure
dirs = struct;
dirs.root = fixpath(rootdir);

% does the rootdir exist
n.files_in_dir = L(dir(dirs.root));
if n.files_in_dir == 0
  error('input:error','no such rootdir');
end

% fix
dirs = fix_dirs_struct(dirs.root);


%% run on data set
% ====================

t0 = clock;

if REGRESSED
  B0_f32_regression(dirs);
  A1_convert_f32s(dirs, 'regressed');
else
  A1_convert_f32s(dirs);
end

A2_autocut_clusters(dirs);
A3_analyse_clusters(dirs,'clusters_pentatrodes');


end




%% ----
function directory = change_main_directory(directory)

% query
if nargin==0, directory = pickdir;
else
  try
    directory = pickdir(directory);
  catch
    directory = pickdir;
  end
end

% does the directory exist
n.files_in_dir = L(dir(directory));
if n.files_in_dir == 0
  fprintf('\n*** error: no such directory. ***\n\n');
  directory = change_main_directory(directory);
end
% does the directory have any src files
n.srcfiles = L(dir([directory '*.src']));
n.bwvtfiles = L(dir([directory '*.bwvt']));
if n.srcfiles + n.bwvtfiles == 0
  fprintf('\n*** error: no src files or bwvt files there. ***\n\n');
  directory = change_main_directory(directory);
end
end

