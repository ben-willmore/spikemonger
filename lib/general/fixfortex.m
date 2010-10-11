function str = fixfortex(str)
  % FIXFORTEX
  %   fixfortex(str)
  %
  % adds preceding '\' to any '_' to prevent any crappy tex rendering

toreplace = strfind(str,'_');

for jj=L(toreplace):-1:1
  str = [str(1:(toreplace(jj)-1)) '\' str(toreplace(jj):end)]; %#ok<AGROW>
end

end