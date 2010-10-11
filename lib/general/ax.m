function a = ax(nrows,ncols,varargin)  
  % a = ax(nrows,ncols,count)
  % a = ax(nrows,ncols,whichrow,whichcol)
  % a = ax(..., 'gapx', gapx, 'gapy', gapy)
  % a = ax(..., 'offset', offset)
  %
  % creates a new axis, like with subplot, but with more control.
  %   nrows = number of rows
  %   ncols = number of columns
  %   whichrow = which row
  %   whichcol = which column
  % 
  % By default, spreads out gaps of total size 20% of figure size.
	% This can be changed with the gapx and gapy (default=0.2) parameters.
  %
  % Offset parameter shifts the position of the graph by a 4-vector offset
  %  [x_left y_bottom x_right y_top]
  
  
  % defaults
  offset = [0 0 0 0];
  gapx = 0.2;
  gapy = 0.2;
  
  if nargin>=4 & isnumeric(varargin{2})
    whichrow = varargin{1};
    whichcol = varargin{2};
  else
    count = varargin{1};
    mat = nan(nrows,ncols)';
    mat(count) = 1;
    mat = mat';
    [whichrow whichcol] = find(mat>0);
  end
  
  
  % parse varargin
  if nargin>=5 
    gapx = getarg(varargin, 'gapx', gapx);
    gapy = getarg(varargin, 'gapy', gapy);    
    offset = getarg(varargin, 'offset', offset);
  end
  
  % size
  w = (1-gapx) / ncols;
  h = (1-gapy) / nrows;
  
  % position
  pos = spaxpos(w,h,nrows,ncols,whichrow,whichcol);
  
  % apply offset
  pos(1) = pos(1) * (1-offset(1)-offset(3)) + offset(1);
  pos(2) = pos(2) * (1-offset(2)-offset(4)) + offset(2);
  
  % make
  a = axes('position',pos);
  