function C = cluster_delete(C,id)
  % C = cluster_delete(C)
  %
  % helper for cluster_ui.m
  
  n.C = L(C.fsp);
  tokeep = setdiff(1:n.C, id);
  
  varlist = fieldnames(C);
  for vv=1:L(varlist)
    C.(varlist{vv}) = C.(varlist{vv})(tokeep);
  end