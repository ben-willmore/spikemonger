function data=dscFileRead(fname);
% function data=dscFileRead(fname);
%    reads a BrainWare spike data file exported with "save spike counts as 32-bit binary" 
%    and export option set to detailed (.DSC files)

data=[];

f=fopen(fname,'r');
if f < 0 
    error(['Could not open file ' fname]);
end;
numSweeps=fread(f,1,'float32');
ii=0;
while ~isempty(numSweeps);
   ii=ii+1;
   data(ii).counts=fread(f,[2,round(numSweeps)],'float32');
   numStimParams=fread(f,1,'float32');
   data(ii).stim=fread(f,round(numStimParams),'float32');
   numSweeps=fread(f,1,'float32');
end;
fclose(f);
% disp(['Read data for ' int2str(ii) ' sets']);
