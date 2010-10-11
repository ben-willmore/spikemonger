function fprintf_bullet(str,n)
  % fprintf_bullet(str,n)
  
  if nargin==1
    n=1;
  end
  
  switch n
    case 1
      fprintf(['  - ' str ]);
    case 2
      fprintf(['    * ' str ]);
    case 3
      fprintf(['      o ' str ]);
    otherwise
      fprintf([repmat(' ',1,n) '      * ' str ]);
  end
  
