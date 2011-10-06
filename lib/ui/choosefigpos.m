function pos = choosefigpos(num)
  % choose a position for spikemonger figure
  
  % proportion of total width to devote to each window
  xprop = [3/8 1/8 1/6 1/6 1/6];
  
  % if two screens are available, multiply the above widths by two
  % and put windows on these screens:
  screennum = [1 1 2 2 2];
  
  
  mp = get(0, 'monitorpositions');
  
   
  switch computer
    case 'PCWIN'
      % convert mp to [xoffset, yoffset, wid, hgt]
      bottompad = 40;
      ys = mp(:,4);
      mp(:, 3) = mp(:, 3) - mp(:, 1) + 1;
      mp(:, 4) = mp(:, 4) - mp(:, 2) + 1;
      
      if size(mp, 1)>1
        mp(2:end, 2) = ys(1) - ys(2:end);
      end
 
    otherwise
      % on linux, mp should already be in the right format  
      bottompad = 40;

  end
  
  nscreens = size(mp, 1);
    
  if nscreens==1
    xstart = [0 cumsum(xprop)];
    
    xpos = mp(1) + mp(3)*xstart(num);
    xwid = mp(3)*xprop(num);
    ypos = mp(2) + bottompad;
    ywid = mp(4) + 1-bottompad;
  
  else
    xprop = xprop * 2;
    xstart = [0 cumsum(xprop.*(screennum==screennum(num)))];
    xpos = mp(screennum(num), 1) + mp(screennum(num), 3)*xstart(num);
    xwid = mp(screennum(num), 3)*xprop(num);
    ypos = mp(screennum(num), 2) + bottompad;
    ywid = mp(screennum(num), 4) + 1-bottompad;

  end
  
  pos = [xpos ypos xwid ywid]
  %keyboard
  