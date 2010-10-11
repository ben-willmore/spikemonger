function str = path_for_fprintf(str)
  % FPRINTF_PATH
  %   fprintf_path(str)
  %
  % adds preceding '\' to any '\' to prevent any crappy crap rendering 

toreplace = strfind(str,'\');

for jj=L(toreplace):-1:1
  str = [str(1:(toreplace(jj)-1)) '\' str(toreplace(jj):end)]; %#ok<AGROW>
end

end