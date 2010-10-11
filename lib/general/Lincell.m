function lengths = Lincell(c)
  % LINCELL
  %   Lincell(c)
  %
  % returns a list of all the lengths of the elements of a cell.
  
  if ~iscell(c)
    ME = MException('input:error','input argument is not a cell');
    throw(ME);
  end
  
  if (size(c,1)==1 | size(c,2)==1 )
    lengths = zeros(size(c));
    for ii=1:L(c)
      lengths(ii) = L(c{ii});
    end
    
  elseif L(size(c))==2
    lengths = zeros(size(c));
    for ii=1:size(c,1)
      for jj=1:size(c,2)
        lengths(ii,jj) = L(c{ii,jj});
      end
    end
    
  else
    ME = MException('input:error','as yet, only supports 1d or 2d cells - update code');
    throw(ME);
  end
  
end
    