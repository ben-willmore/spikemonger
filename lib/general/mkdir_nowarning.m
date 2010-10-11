function mkdir_nowarning(dirname)
  warning off MATLAB:MKDIR:DirectoryExists;
  mkdir(dirname);
  warning on MATLAB:MKDIR:DirectoryExists;
end