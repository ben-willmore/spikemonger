function data=damFileRead(fname)
% function data=damFileRead(fname)
%
% damFileRead reads voltage wave form data "DAM" files recorded 
% with BrainWare. Data will be organised into a structured array
% where each entry of the struct represents one data sweep.
% See BrainWare32.hlp index item ".dam files" for 
% further information on how to record data to DAM files.
%

data=[];

f=fopen(fname,'r');
if f==-1,
    error(sprintf('Cannot open file %s',fname));
end;
i=0;
stamp=fread(f,1,'float64'); % read time stamp for 1st data sweep
while ~isempty(stamp);
   i=i+1;
   data(i).timestamp=stamp;
   % stimulus object follows
   data(i).stimIndex=fread(f,1,'int16'); % stimulus index
   numPar=fread(f,1,'int16'); % how many stimulus parameters are there?
   stim.params=[];
   % read stimulus parameter names
   for p=1:numPar
      % read name of stimulus parameter p
      slen=fread(f,1,'uint8');
      sbuf=fread(f,slen,'uchar');
      c=find(sbuf < 32);
      sbuf(c)=[];
      sbuf=char(sbuf');
      stim.params=[stim.params,cellstr(sbuf)];
   end;
   % read stimulus parameter values
   stim.values=fread(f,numPar,'float32'); 

   data(i).stim=stim;
   % read length of data sweep
   sigLen=fread(f,1,'int32');
   % read data sweep itself
   data(i).signal=fread(f,sigLen,'int16');  
   % read time stamp for next data sweep
   stamp=fread(f,1,'float64');
end;
fclose(f);
% disp(['Read data for ' int2str(i) ' sweeps']);

