function bwcullunwantedf32clusters(data,textdata,rootdir)
    % bwcullunwantedf32clusters
    %
    %   after importing the .xls file, and creating the f32 files etc, will
    %   need to get rid of the unwanted clusters, as specified in data /
    %   textdata files.
    %
    % NCR 2008-07-08
    %   note: this might be very parochial code, so ignoring it is prob
    %   wise
    
% ensure the pathectory ends with a "\"
    if ~strcmp(rootdir(end),'\')
        rootdir = [rootdir '\'];
    end

% create temp dirs within the objects.f32 and tones.f32 subdirectories
    objectsdir = [rootdir 'objects.f32\'];
    tonesdir = [rootdir 'tones.f32\'];
    
    mkdir([objectsdir 'keep\']);
    mkdir([objectsdir 'cull\']);
    mkdir([tonesdir 'keep\']);
    mkdir([tonesdir 'cull\']);
    
% run through objects
    for ii=1:size(data,1)
        
        % filename
        objectfname = [lower(textdata{ii+1,1}) '-objects-' n2s(data(ii,1)) ...
            '-C' n2s(data(ii,2)) '.f32'];
        
        try

            % move object to keep/cull?
            if strcmp(textdata{ii+1,4},'Y')
                movefile([objectsdir objectfname], [objectsdir 'keep\']);
            elseif strcmp(textdata{ii+1,4},'P')
                movefile([objectsdir objectfname], [objectsdir 'keep\']);
            else
                %movefile([objectsdir objectfname], [objectsdir 'cull\']);
            end
            
        catch            
            display(['error moving ' objectfname]);            
        end
        
    end
    
% run through tones
    for ii=1:size(data,1)
        
        % filename
        tonefname  = [lower(textdata{ii+1,1}) '-tones-' n2s(data(ii,1)) ...
            '-C' n2s(data(ii,2)) '.f32'];

        try

            % move tone to keep/cull?
            if strcmp(textdata{ii+1,5},'Y')
                movefile([tonesdir tonefname], [tonesdir 'keep\']);
            elseif strcmp(textdata{ii+1,5},'P')
                movefile([tonesdir tonefname], [tonesdir 'keep\']);
            else
                %movefile([tonesdir tonefname], [tonesdir 'cull\']);
            end
            
        catch            
            display(['error moving ' tonefname]);
        end

        
    end
    
end