function num = demandcombinationnumberinput(query,allowable_answers)
  % num = demandcombinationnumberinput(query,allowable_answers)
  
  if nargin==1, 
    allowable_answers = []; 
  end
  
  
  num = input(query);
  
  if isempty(num)
    num = demandnumberinput(query,allowable_answers);
  end
  
  if ~isnumeric(num)
    num = demandnumberinput(query,allowable_answers);
  end
  
  if ~isfinite(num)
    num = demandnumberinput(query,allowable_answers);
  end
    
  if ischar(allowable_answers)
    switch allowable_answers
      case 'nonnegative'
        if any(num < 0),          num = demandnumberinput(query,allowable_answers); end
      case 'positive'
        if any(num <= 0),         num = demandnumberinput(query,allowable_answers); end
      case 'integer'
        if any(~(mod(num,1)==0)), num = demandnumberinput(query,allowable_answers); end
      case {'positiveinteger','positive_integer'}
        if any(num <= 0),         num = demandnumberinput(query,allowable_answers); end
        if any(~(mod(num,1)==0)), num = demandnumberinput(query,allowable_answers); end
      case {'nonnegative_integer'}
        if any(num < 0),          num = demandnumberinput(query,allowable_answers); end
        if any(~(mod(num,1)==0)), num = demandnumberinput(query,allowable_answers); end
      otherwise
        error('input:error','have not yet defined this allowable_answers -- add to function!');
    end
  end
  
  if isnumeric(allowable_answers)
    if ~ismember(num,allowable_answers), num = demandnumberinput(query,allowable_answers); end
  end
  
  return;
  
end