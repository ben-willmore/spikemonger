function noticks(ax)
  if nargin==0
    ax = gca;
  end
  
  set(ax,'xtick',[],'ytick',[]);