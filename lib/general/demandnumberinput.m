function num = demandnumberinput(query,allowable_answers)
  % str = demandnumberinput(query,allowable_answers)
  
  if nargin==1, 
    allowable_answers = []; 
  end
  
  try
    num = input(query);
  catch
    num = demandnumberinput(query,allowable_answers);
    return;
  end
  
  if isempty(num)
    num = demandnumberinput(query,allowable_answers);
    return;
  end
  
  if ~isnumeric(num)
    num = demandnumberinput(query,allowable_answers);
    return;
  end
  
  if ~isfinite(num)
    num = demandnumberinput(query,allowable_answers);
    return;
  end
  
  if L(num)>1
    num = demandnumberinput(query,allowable_answers);
    return;
  end
  
  if ischar(allowable_answers)
    switch allowable_answers
      case 'nonnegative'
        if num < 0,   num = demandnumberinput(query,allowable_answers); return; end
      case 'positive'
        if num <= 0,  num = demandnumberinput(query,allowable_answers); return; end
      case 'integer'
        if ~(mod(num,1)==0), num = demandnumberinput(query,allowable_answers); return; end
      case {'positiveinteger','positive_integer'}
        if num <= 0,  num = demandnumberinput(query,allowable_answers); return; end
        if ~(mod(num,1)==0), num = demandnumberinput(query,allowable_answers); return; end
      case {'nonnegative_integer'}
        if num < 0,   num = demandnumberinput(query,allowable_answers); return; end
        if ~(mod(num,1)==0), num = demandnumberinput(query,allowable_answers); return; end
      otherwise
        error('input:error','have not yet defined this allowable_answers -- add to function!');
    end
  end
  
  if isnumeric(allowable_answers)
    if ~ismember(num,allowable_answers), num = demandnumberinput(query,allowable_answers); return; end
  end
  
  if iscell(allowable_answers)
    for ii=1:L(allowable_answers)
      aaii = allowable_answers{ii};
      if isequal(aaii,'max')
        if num > allowable_answers{ii+1}, num = demandnumberinput(query,allowable_answers); return; end
      elseif isequal(aaii,'min')
        if num < allowable_answers{ii+1}, num = demandnumberinput(query,allowable_answers); return; end
      end
    end
  end
  
  return;
  
end