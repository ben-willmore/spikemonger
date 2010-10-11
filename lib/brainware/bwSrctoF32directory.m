function bwsrctof32directory(path)
    % BWSRCTOF32DIRECTORY
    %
    % converts .src to .f32 for an entire directory
    % specified by path
    %
    % NCR 2008-05-20

    
    % ensure the pathectory ends with a "\"
        if ~strcmp(path(end),'\')
            path = [path '\'];
        end

    % list pathectory contents
        lspath = lsnr(path);
    
    % perform conversion
        for ii=1:size(lspath,1),
            if ~isempty(strfind(lspath{ii},'.src'))
                bwsrctof32([path lspath{ii}]);
            end
        end
        
end