function t = ylabel8bf(in1, in2)
  
  if nargin==1
    str = bfify(in1);
    t = ylabel(str, 'fontsize', 8);
  
  elseif nargin==2
    if ischar(in1)
      str = bfify(in1);
      t = ylabel(str, in2, 'fontsize', 8);
    else
      str = bfify(in2);
      t = ylabel(in1, str, 'fontsize', 8);
    end
    
  else
    error('input:error', 'ylabel8bf currently only defined for two inputs');
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
