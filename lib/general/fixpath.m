function path = fixpath(path)
    % FIXPATH
    %   fixpath(path) ensures that the path ends with a '/'
    
    if isunix
      if ~strcmp(path(end),'/')
          path = [path '/'];
      end
      
    elseif ismac
      if ~strcmp(path(end),'/')
          path = [path '/'];
      end

    elseif ispc
      if ~strcmp(path(end),'\')
          path = [path '\'];
      end      
    end
      
end
