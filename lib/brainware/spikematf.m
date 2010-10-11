function data=spikematf(fname, resolution);
% function data=spikematf(fname, resolution);
% Reads binary spike data file "fname" generated with
% BrainWare 6.1 "File | Save As | Spike Times as Binary.
% Produces a structured array of the data, 
%   similar to function "spikedatf", but individual data sweeps 
%   are represented as sparse arrays where one bin corresponds to a
%   timestep of "resolution" miliseconds
% (c) Jan Schnupp, January 1999
%
data=[];
f=fopen(fname, 'r');

numsets=0;
numsweeps=0;
totalsweeps=0;
totalspikes=0;
ii=fread(f,1,'float32');
while ~isempty(ii);
   
   switch ii
   case (-2) % new dataset
      % compact data from previous set, if any 
      if ( numsets > 0 )
         data(numsets).sweeps=sparse(data(numsets).sweeps);
      end;
      % increment counters and read header info for next set
      numsets=numsets+1; 
      numsweeps=0;
      % read sweeplength
      data(numsets).sweeplength=fread(f,1,'float32');
      % read stimulus parameters
      numparams=fread(f,1,'float32');
      data(numsets).stim=[fread(f,numparams,'float32')];
      data(numsets).sweeps=[];
   case (-1) % new sweep
      numsweeps=numsweeps+1;
      totalsweeps=totalsweeps+1;
      data(numsets).sweeps=[data(numsets).sweeps ; ...
            zeros(1,ceil(data(numsets).sweeplength/resolution))];
      
   otherwise % read spike time for next spike in current sweep
      binIdx=floor(ii/resolution)+1;
      if binIdx <= size(data(numsets).sweeps,2)
         data(numsets).sweeps(numsweeps,binIdx)=...
           data(numsets).sweeps(numsweeps,binIdx)+1; 
        totalspikes=totalspikes+1;
     else
        warning(sprintf('Spike beyond sweeplength at %f ms, set %d, sweep %d',ii,numsets,numsweeps));
     end;
   end;
   
   ii=fread(f,1,'float32');
end;
% compact data from last set, if any 
if ( numsets > 0 )
   data(numsets).sweeps=sparse(data(numsets).sweeps);
end;

fclose(f);
disp(sprintf('read %d sets, %d sweeps, %d spikes',...
   numsets,totalsweeps, totalspikes))