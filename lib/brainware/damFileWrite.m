function damFileWrite(fname,data)
% function damFileRead(fname,data)
%
% damFileWrite writes voltage wave form data struct as read in
% with damFileRead back to dam file fname.
%
% useful for reading, filtering, writing dam files
%

f=fopen(fname,'W');
if f==-1,
    error(sprintf('Cannot write file %s',fname));
end;
for ii=1:length(data);
    fwrite(f,data(ii).timestamp,'float64');
    fwrite(f,data(ii).stimIndex,'int16');
    % write stimulus info
    numStim=length(data(ii).stim.values);
    fwrite(f,numStim,'int16');
    for ss=1:numStim,
        % write stimulus parameter names
        fwrite(f,length(data(ii).stim.params{ss}),'uint8');
        fwrite(f,data(ii).stim.params{ss},'uchar');
    end;
    fwrite(f,data(ii).stim.values,'float32');
    % write signal length, then signal
    fwrite(f,length(data(ii).signal),'int32');
    fwrite(f,round(data(ii).signal),'int16');  
end;
fclose(f);

