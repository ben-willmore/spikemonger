function ax = axatpos(w,h,nrows,ncols,whichrow,whichcol,offset)  
  % ax = axatpos(w,h,nrows,ncols,count)
  % ax = axatpos(w,h,nrows,ncols,whichrow,whichcol)
  % ax = axatpos(w,h,nrows,ncols,whichrow,whichcol,offset)
  %
  % creates a new axis, like with subplot, but with more control.
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
  
  if nargin<7
    offset = [0 0 0 0];
  end
  
  if ~(L(offset)==4)
    error('input:error','offset should be a (1x4) vector');
  end
  
  ax = axes('position',spaxpos(w,h,nrows,ncols,whichrow,whichcol)+offset);