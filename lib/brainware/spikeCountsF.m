function data=spikeCountsF(fname);
% function data=spikeCountsF(fname);
%    reads a BrainWare spike data file exported with "save spike counts as 32-bit binary" 
%    and export option set to detailed

data=[];

f=fopen(fname,'r');
swps=fread(f,1,'float32');
i=0;
while ~isempty(swps);
   i=i+1;
   data(i).counts=fread(f,[2,round(swps)],'float32');
   stim=fread(f,1,'float32');
   data(i).stim=fread(f,round(stim),'float32');
   swps=fread(f,1,'float32');
end;
% disp(['Read data for ' int2str(i) ' sets']);
