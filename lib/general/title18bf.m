function t = title18bf(in1, in2)
  
  if nargin==1
    str = bfify(in1);
    t = title(str, 'fontsize', 18);
  
  elseif nargin==2
    if ischar(in1)
      str = bfify(in1);
      t = title(str, in2, 'fontsize', 18);
    else
      str = bfify(in2);
      t = title(in1, str, 'fontsize', 18);
    end
    
  else
    error('input:error', 'title18bf currently only defined for two inputs');
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
