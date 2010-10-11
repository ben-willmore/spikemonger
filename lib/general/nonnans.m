function varargout = nonnans(varargin)
  
  if nargin==1
    y = varargin{1};
    varargout{1} = y(~isnan(y));
    return
    
  elseif nargin==nargout
    if L(unique(Lincell(varargin))) > 1
      error('input:error','arguments must all be the same (1D for now: fix) size');
    end
    
    tok = true(size(varargin{1}));
    for ii=1:nargin
      tok = tok & ~isnan(varargin{ii});
    end
    for ii=1:nargout
      varargout{ii} = varargin{ii}(tok);
    end
    
  else
    error('output:error',['number of outputs must be number of inputs, here = ' n2s(nargin)]);
    
  end