function spikemonger(rootdir)
% spikemonger(rootdir)
%
% Main wrapper file for running spikemonger over a set of penetrations.
% Ensure your directory structure is as follows:
%   .         - spikemonger directory (ie the current directory )
%   ./data    - where your data is (could be anything you like),
%   with all the .src/.bwvt files in this rootdir

% ======================
% SPIKEMONGER v1.0.0.5
% ======================
%   - NCR 11-Jun-2010
%   - distributed under GPL v3 (see COPYING)


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

% does the rootdir have any files
n.srcfiles  = L(dir([dirs.root '*.src']));
n.bwvtfiles = L(dir([dirs.root '*.bwvt']));
if n.srcfiles + n.bwvtfiles == 0
  %dirs.root = change_main_directory(dirs.root);
end

% fix
dirs = fix_dirs_struct(dirs.root);


%% run on data set

t0 = clock;

A1_convert_bwvts(dirs);
A2_autocut_clusters(dirs);
A3_analyse_clusters(dirs,'clusters_pentatrodes');

%{
try
  dirstr = dirs.root(head(tail(strfind(dirs.root,'/'),2))+1:end-1);
catch
  dirstr = droptail(dirs.root);
end
fprintf_subtitle(['total time for ' dirstr ':   *** ' timediff(t0,clock) ' ***']);
%}

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

