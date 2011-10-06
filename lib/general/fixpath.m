function path = fixpath(path)
    % FIXPATH
    %   fixpath(path) ensures that the path ends with filesep (/ or \)
    
    if isunix
      if ~strcmp(path(end), filesep)
          path = [path filesep];
      end
      
    elseif ismac
      if ~strcmp(path(end), filesep)
          path = [path filesep];
      end

    elseif ispc
      if ~strcmp(path(end), filesep)
          path = [path filesep];
      end      
    end
      
end
