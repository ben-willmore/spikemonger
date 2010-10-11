function [b,which_kept] = unique_within(a,da)
  % [b,which_kept] = unique_within(a,da)
  

[b wk] = unique(a);
wk2 = cell(1,da);
for ii=1:da
  [b wk2{ii}] = setdiff(b,b+ii);
end

which_kept = pick(1:L(a), wk);
for ii=1:da
  which_kept = pick(which_kept,wk2{ii});
end