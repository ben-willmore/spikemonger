function exportf32Tomatlab(sourcepath, destpath)
    % exportf32Tomatlab
    %
    %   takes a directory choc full of .f32 files, and converts them into
    %   .mat files. These are placed in a destination directory of your
    %   delight.
    %
    % NCR 2008-07-08



% ensure the pathectories ends with filesep
    if ~strcmp(sourcepath(end), filesep)
        sourcepath = [sourcepath filesep];
    end
    if ~strcmp(destpath(end), filesep)
        destpath = [destpath filesep];
    end

% run through all files    
    files = dir([sourcepath '*.f32']);

    for ii = 1:length(files)

        fileName = files(ii).name;    
        data = spikematf([sourcepath fileName],1);    
        save([destpath, fileName(1:end-4), '.mat'],'data');

    end
    
end