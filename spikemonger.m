function spikemonger(rootdir, varargin)
% spikemonger(rootdir)

%% parse varargin
% ================

REGRESSED = false;
PRE_MERGE = false;
POST_MERGE = false;

try
  if nargin>1
    if any(ismember({'regressed'}, varargin))
      REGRESSED = true;
    end  
    if any(ismember({'pre-merge'}, varargin))
      PRE_MERGE = true;
    end  
    if any(ismember({'post-merge'}, varargin))
      POST_MERGE = true;
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

args = {};
if REGRESSED
    args = [args, 'regressed'];
end
if PRE_MERGE
  args = [args, 'pre-merge'];
elseif POST_MERGE
  args = [args, 'post-merge'];
end
A1_convert_datafiles(dirs, args{:});

if ~PRE_MERGE
  A2_autocut_clusters(dirs);
  A3_analyse_clusters(dirs,'clusters_pentatrodes');
end


end

