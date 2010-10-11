function t = title16bf(in1, in2)
  
  if nargin==1
    str = bfify(in1);
    t = title(str, 'fontsize', 16);
  
  elseif nargin==2
    if ischar(in1)
      str = bfify(in1);
      t = title(str, in2, 'fontsize', 16);
    else
      str = bfify(in2);
      t = title(in1, str, 'fontsize', 16);
    end
    
  else
    error('input:error', 'title16bf currently only defined for two inputs');
  end
   
end 
  

function s = bfify(s)

  if ischar(s)
    s = ['{\bf' s '}'];
  elseif iscell(s)
    for ii=1:L(s)
      s{ii} = bfify(s{ii});
    end
  else
    error('input:error','s is not a string');
  end

end
