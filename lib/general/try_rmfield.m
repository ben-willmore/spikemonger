function s = try_rmfield(s, fields)
  % s = try_rmfield(s, fields)
  %
  % tries to remove the fields, but doesn't give an error if there's a
  % problem
  
  for ff=1:L(fields)
    fi = fields{ff};
    try
      s = rmfield(s, fi);
    catch
    end
  end