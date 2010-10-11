function nextVal=staircase(StimGridColumn,InitialValue,Step, ...
   NumReversals, AdditionalComment,LowerLimit,UpperLimit);
% function staircase(StimGridColumn,InitialValue,Step,NumReversals, ...
%              AdditionalComment,LowerLimit,UpperLimit);
%   uses DDE to direct BrainWare in a "staircase" automatic 
%   threshold search for the currently selected cluster 
%   in the data file currently associated with electrode channel 1.
%   "StimGridColumn" indicates the column of the parameter to 
%   threshold in BrainWare's stimulus grid.
%   "AdditionalComment" (optional) will be added to the comment 
%      posted to the BW data file.
%   "LowerLimit" and "UpperLimit" (optional) set bounds for the stimulus
%      parameter that the staircase should not step beyond.
%
%    Jan Schnupp, April 1999

% find the name of the current data file for electrode one
electrodeChan=ddeinit('BrainWare32','Channel #1');
datafile=ddereq(electrodeChan,'datafile',[1,1]);
ddeterm(electrodeChan);
% exit if no valid file name string was returned
if (datafile==0) | (strcmp(datafile,['0' char(10)])) % "|" stands for "OR" 
   error('Cannot obtain data file for electrode 1. Channel not open??');
end;

% The returned file name may contain a new line character. 
% If so, remove.
if datafile(length(datafile))==char(10) 
   datafile(length(datafile))=[];
end;

% abandon if there is no data file associated with channel 1
if strcmp(datafile,'no associated datafile')
   disp('No data file associated with electrode 1!');
   error(' Record initial data point and determine cluster boundary first!');
end;


% Verify that we can get a DDE link to datafile, and that can return 
% response stats.
% If no cluster is selected "response" will be "not available" ("N/A")
response=getBWResponseString(datafile);
if length(response) > 2
   if strcmp(response(1:3),'N/A')
      disp('BrainWare signaled response for current cluster NOT AVAILABLE!');
      error('No cluster selected?');
   end;
end;


% find the name of the stimulus parameter 
% that we are running the staircase on
%   - we use that later to write a comment string
sgridchan=ddeinit('BrainWare32','StimulusTable');
ddepoke(sgridchan,'Column',StimGridColumn);
paramName=ddereq(sgridchan,'ParameterName',[1,1]);
ddeterm(sgridchan);

% get an initial data point
reversalsDone=0;
nextVal=InitialValue;
setStimParam(StimGridColumn,nextVal);
response=getBWResponse(datafile); % getBWResponse() is defined below
if response(1) > response(2) 
   % i.e. response is greater than error estimate
   direction = -1; % descending
else
   direction = 1; % ascending
end;

% Now run staircase until the required number of reversals is 
% accomplished. If last reversal happened below threshold 
% we do one more.
while ((reversalsDone < NumReversals) | ... 
   ( direction > 0 )) % I want to stop on a positive response
   % if direction is descending and we reversed direction we'll
   % now be ascending. In this case the last response was not 
   % significant so do one more
   
   nextVal=nextVal+(Step*direction);
   
   % if nextVal lies outside the specified limits then stop
   if exist('UpperLimit')
      if nextVal > UpperLimit
         postComment(...
            sprintf('Threshold exceeds upper limit of %g for %s',...
            UpperLimit,paramName),...
            datafile, AdditionalComment); 
         return;
      end;
   end;
   if exist('LowerLimit')
      if nextVal < LowerLimit
         postComment(...
            sprintf('Threshold exceeds lower limit of %g for %s',...
            LowerLimit,paramName),...
            datafile, AdditionalComment); 
         return;
      end;
   end;
   
   % get data for nextVal
   setStimParam(StimGridColumn,nextVal);
   response=getBWResponse(datafile);
   % decide whether we need to do a reversal
   if ((response(1) <= response(2)) & (direction < 0))...
         | ((response(1) > response(2)) & (direction > 0))
      % must do a reversal :- reverse direction and halve step size
      direction = -direction;
      Step= Step/2;
      reversalsDone = reversalsDone+1;
   end;      
end;  

% note the determined threshold in a comment posted 
% to the BW data file
postComment(...
   sprintf('Threshold %g determined in staircase on %s',nextVal,...
   paramName),...
   datafile, AdditionalComment); % postComment() is defined below

% display last direction and response 
direction
response

% DONE !


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function postComment(aComment, datafile, AddComment);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  attaches comment string 'aCommment' to a BW datafile
dataChan=ddeinit('BrainWare32',datafile);
if dataChan==0 
   error(['Could not open DDE topic ' datafile]);
end;
if ~isempty(AddComment)
   aComment=[AddComment ' ' aComment];
end;
ddepoke(dataChan,'Comment', aComment);
ddeterm(dataChan);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function setStimParam(acol, aval);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  sends stimulus parameter 'aval' to stimulus grid at column 'acol'
sgridchan=ddeinit('BrainWare32','StimulusTable');
a=ddepoke(sgridchan,'Editing','1');
if ddereq(sgridchan,'Editing',[1,1]) ~= '1'
   ddeterm(sgridchan);
   error('Cannot edit stimulus grid!');
end;
ddepoke(sgridchan,'Column',acol);
ddepoke(sgridchan,'Cell',aval);
ddepoke(sgridchan,'Editing','0');
ddeterm(sgridchan);


%%%%%%%%%%%%%%%%%%%%%%
function resps=getBWResponse(datafile);
%%%%%%%%%%%%%%%%%%%%%%
% records a data point and returns response

% fire off recording by setting status to 'r' (record)
% and wait for completion 
chan=ddeinit('BrainWare32','settings');
waitPeriod=ddereq(chan,'stimrepeats') * ddereq(chan,'stimperiod');
ddepoke(chan,'status','r');
pause(waitPeriod/1000);
status=ddereq(chan,'status',[1,1]);
% wait for status to be 'idle', i.e. recording completed
while status(1) ~= 'i'
   if status==0 
      error('DDE connection timed out !');
   end;
   if strcmp(status(1:3),'err')
      error('BrainWare signaled error during recording.');
   end;
   status=ddereq(chan,'status',[1,1]);
end;  
ddeterm(chan);

response=getBWResponseString(datafile);

% "response" should be a string of format "evoked activity +/- error"
% sscanf() will form a two-element vector "response" with elements
% [evoked activity, error] from this, provided the format matches.
% If the format does not match "errmsg" will not be empty, 
% and we abort
[resps,count,errmsg,nextindex] = sscanf(response,'%f +/- %f');
if ~isempty(errmsg) 
   error(['DDE topic "reponse" returned illegal format string ' ...
         response]);
end;


%%%%%%%%%%%%%%%%%%%%%%
function response=getBWResponseString(datafile);
%%%%%%%%%%%%%%%%%%%%%%

dataChan=ddeinit('BrainWare32',datafile);
if dataChan==0 
   error(['Could not open DDE topic ' datafile]);
end;
response=ddereq(dataChan,'response',[1,1]);
ddeterm(dataChan);

