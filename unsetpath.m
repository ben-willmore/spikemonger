warning off MATLAB:rmpath:DirNotFound;

rmpath(genpath([pwd filesep 'lib' filesep]));

warning on MATLAB:rmpath:DirNotFound