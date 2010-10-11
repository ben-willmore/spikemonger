function pos = spaxpos(w,h,nrows,ncols,whichrow,whichcol)
  % pos = spaxpos(w,h,nrows,ncols,whichrow,whichcol)
  %
  % where:
  %   w = width of each
  %   h = height of each
  %   nrows = number of rows
  %   ncols = number of columns
  %   whichrow = which row
  %   whichcol = which column
    
  if nargin==5
    count = whichrow;
    mat = nan(nrows,ncols)';
    mat(count) = 1;
    mat = mat';
    [whichrow whichcol] = find(mat>0);
  end

  gapx = (1 - ncols*w)/(ncols+1);
  gapy = (1 - nrows*h)/(nrows+1);
  
  xi = w*(whichcol-1) + gapx*whichcol;
  xf = xi + w;
  
  yf = 1 - h*(whichrow-1) - gapy*whichrow;
  yi = yf - h;
  
  pos = [xi yi w h];