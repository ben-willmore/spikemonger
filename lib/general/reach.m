function result = reach(parent,daughter,use_a_cell)
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


%% collate
%   for ii=1:L(parent)
%     parent(ii).reachtemp = eval(['parent(ii).' daughter]);
%   end
% 
%   switch use_a_cell
%     case 0
%       result = [parent.reachtemp];
%     case 1
%       result = {parent.reachtemp};
%   end

%% collate
  st = struct('reachtemp',cell(1,L(parent)));
  for ii=1:L(st)
    st(ii).reachtemp = eval(['parent(ii).' daughter]);
  end

  switch use_a_cell
    case 0
      result = [st.reachtemp];
    case 1
      result = {st.reachtemp};
  end
  
end