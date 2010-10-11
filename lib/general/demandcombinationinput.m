function str = demandcombinationinput(query,allowable_answers)
  % str = demandinput(query,allowable_answers)
  
  if iscell(allowable_answers)
    allowable_answers = cell2mat(allowable_answers);
  end
  
  
  str = input(query,'s');
  if all(ismember(str,allowable_answers))
    return;
  else
    str = demandinput(query,allowable_answers);
  end
  
end