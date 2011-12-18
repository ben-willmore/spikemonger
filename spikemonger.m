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
  A1_convert_datafiles(dirs, 'regressed');
else
  A1_convert_datafiles(dirs);
end

A2_autocut_clusters(dirs);
A3_analyse_clusters(dirs,'clusters_pentatrodes');


end

