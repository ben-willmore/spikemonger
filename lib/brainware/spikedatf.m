function data=spikedatf(fname);
% reads binary spike data file "fname" generated with
% BrainWare 6.1 "File | Save As | Spike Times as Binary"
% (c) Jan Schnupp, Feb 1999
%
f=fopen(fname, 'r');

numsets=0;
numsweeps=0;
totalsweeps=0;
totalspikes=0;
i=fread(f,1,'float32');
while ~isempty(i);

   switch i
   case (-2) % new dataset
	  numsets=numsets+1; 
     numsweeps=0;
     % read sweeplength
	  data(numsets).sweeplength=fread(f,1,'float32');
     % read stimulus parameters
     numparams=fread(f,1,'float32');

     data(numsets).stim=fread(f,numparams,'float32');
       
   case (-1) % new sweep
      numsweeps=numsweeps+1;

      totalsweeps=totalsweeps+1;
      data(numsets).sweep(numsweeps).spikes=[];

   otherwise % read spike time for next spike in current sweep
      data(numsets).sweep(numsweeps).spikes=...
			[data(numsets).sweep(numsweeps).spikes i];
      totalspikes=totalspikes+1;
   end;
   
   i=fread(f,1,'float32');

end;
fclose(f);
disp(sprintf('read %d sets, %d sweeps, %d spikes',...
   numsets,totalsweeps, totalspikes))