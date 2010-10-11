function noticklabels(ax)
  if nargin==0
    ax = gca;
  end
  
  set(ax,'xticklabel',{},'yticklabel',{});