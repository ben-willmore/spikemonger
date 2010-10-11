function result = reach2d(parent,daughter,use_a_cell)
    % REACH
    %   reach(parent,daughter)
    % where
    %   - parent is a struct
    %   - daughter is a string
    %
    % allows you to retrieve [parent(ii).daughter] when daughter is a
    % series of substructures.
    %
    % eg consider the structure
    %   animals.dog(1:10).woof.volume
    % matlab allows [animals.dog.woof], to give the 10 woofs, but not
    % [animals.dog.woof.volume].
    %
    % instead, type
    %   reach(animals.dog,'woof.volume')
    
    
 
%% error handling / input processing

if nargin < 3
  use_a_cell = 0;
elseif nargin==3
  if ischar(use_a_cell)
    switch use_a_cell
      case {'y','yes','Y','Yes','YES','c','cell','C','Cell','CELL'}
        use_a_cell = 1;
      otherwise
        use_a_cell = 0;
    end
  end
end

if ~isstruct(parent)
    error('input:error', 'first argument needs to be the structure itself');
end

if ~isa(daughter,'char')
    error('input:error', 'second argument needs to be a string');
end 

if pick(daughter,1)=='.'
    daughter = daughter(2:end);
end

result = [];
for ii=1:size(parent,1)
  result = [result; reach(parent(ii,:),daughter,use_a_cell)];
end
   