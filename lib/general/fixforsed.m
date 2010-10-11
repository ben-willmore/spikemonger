function str = fixforsed(str)
  % FIXFORSED
  %   fixforsed(str)
  %
  % adds preceding '\' to any '.' to prevent any crappy sedding

toreplace = strfind(str,'.');

for jj=L(toreplace):-1:1
  str = [str(1:(toreplace(jj)-1)) '\' str(toreplace(jj):end)]; %#ok<AGROW>
end

end