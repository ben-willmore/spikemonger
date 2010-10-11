function a = axn(varargin)
  % axn is ax with noticks
  
  a = ax(varargin{:});
  noticks(a);
  
end