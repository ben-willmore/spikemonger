function str = demandinput(query,allowable_answers)
  % str = demandinput(query,allowable_answers)
  
  str = input(query,'s');
  if ismember(str,allowable_answers)
    return;
  else
    str = demandinput(query,allowable_answers);
  end
  
end