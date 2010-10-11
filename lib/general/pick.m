function element = pick(list,n,iscell)
  % PICK
  %   pick(list,n) returns list(n)
  %   pick(list,n,'cell') returns list{n}
  %   pick(list,n,'c') returns list{n}
  %
  %   use in circumstances where the syntax doesn't allow for this use
  %
  % NCR 2008-07-08

  if nargin < 3
    if ischar(n)
      element = eval(['list(' n ')']);
    else
      element = list(n);
    end

  elseif nargin == 3
      if strcmp(iscell,'cell') || strcmp(iscell,'c')
        if ischar(n)
          element = eval(['list{' n '}']);
        else
          element = list{n};
        end
      else
          error('input:invalid','argument #3 is not understood');
      end
  end

end
    
    