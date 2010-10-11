function bwcollectsrcstogether(data,textdata,rootdir)
    % BWCOLLECTSRCSTOGETHER
    %
    %   after importing the .xls file, one gets a "data" and a "textdata"
    %   variable. use these, together with the directory where all the
    %   sortedData is kept
    %
    %   this will then extract .src files you want, and put them in a
    %   directory ready for conversion: objects.src.touse
    %
    % eg:
    %    bwcollectsrcstogether(data,textdata,'.\physiolData\expt04-may28th\sortedData\')
    %
    % NCR 2008-07-08
    %   note: this might be very parochial code, so ignoring it is prob wise
    
    
% ensure the pathectory ends with a "\"
    if ~strcmp(rootdir(end),'\')
        rootdir = [rootdir '\'];
    end
    
% destination dirs
    objectdestdir = [rootdir 'objects.src.touse\'];
    tonesdestdir  = [rootdir 'tones.src.touse\'];
    mkdir(objectdestdir);
    mkdir(tonesdestdir);
    
% for loop to run through all the recordings worthy of being collected    
    % objects:
    for ii=1:size(data,1)
        
        % first grab the object metadata
            objectdir   = [rootdir 'objects.src\' textdata{ii+1,1} '\'];
            objectfname = [textdata{ii+1,1} '-objects-' n2s(data(ii,1)) '.src'];
        % copy the object stuff
            copyfile([objectdir objectfname], objectdestdir);
    end
    
    % tones:    
    % (only those requested in 5th column of textdata file)
    for ii=1:size(data,1)
        if ( strcmp(textdata{ii+1,5},'Y') || strcmp(textdata{ii+1,5},'P') )
            tonesdir   = [rootdir 'tones.src\' textdata{ii+1,1} '\'];
            tonesfname = [textdata{ii+1,1} '-tones-' n2s(data(ii,1)) '.src'];
            copyfile([tonesdir tonesfname], tonesdestdir);
        end        
    end
            
% now use bwSrctoF32directory on these bitches!
        
end