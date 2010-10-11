function v=threshTuningCurve(threshParamIndex, atParamIndex, forValues,...
   InitialValue, Step, NumReversals, LowerLimit, UpperLimit);
% function v=threshTuningCurve(threshParamIndex, atParamIndex, forValues, ...
%       InitialValue, Step, NumReversals, LowerLimit, UpperLimit);
%   uses function staircase to run thresholds in BrainWare 
%   for stimulus parameter threshParamIndex 
%   at a number of fixed parameter values specified by 
%   "atParamIndex" and "forValues".
%   InitialValue, Step, NumReversals, LowerLimit and UpperLimit 
%   are passed to function staircase(). (SEE ALSO: staircase.m)
%
%   EXAMPLE: suppose BrainWare is set up to present tone stimuli. Frequency is 
%   specified in column 1 of the stimulus grid, intensity in column 2.
%   You could then use "threshTuningCurve(2,1,[500,1000,2000,4000,8000],50,20,5)"
%   to track thresholds at frequencies 500,1000,..,8000  using a staircase
%   algorithm with 5 reversals, staring at intensity 50 and 
%   incrementing / decrementing initially at 20 dB.
%
%   Jan Schnupp, April 1999

v=[];

% find the name of the stimulus parameter pointed to by atParamIndex
sgridchan=ddeinit('BrainWare32','StimulusTable');
ddepoke(sgridchan,'Column',atParamIndex);
paramName=ddereq(sgridchan,'ParameterName',[1,1]);
% paramName may contain a new line character. If so, remove.
if paramName(length(paramName))==char(10) 
   paramName(length(paramName))=[];
end;

for i=1:length(forValues)
   
   % set up next fixed parameter in list
   a=ddepoke(sgridchan,'Editing','1');
   if ddereq(sgridchan,'Editing',[1,1]) ~= '1'
      ddeterm(sgridchan);
      error('Cannot edit stimulus grid!');
   end;
   ddepoke(sgridchan,'Column',atParamIndex);
   ddepoke(sgridchan,'Cell',forValues(i));
   ddepoke(sgridchan,'Editing','0');
   
   % prepare a little comment to send to the data file
   AdditionalComment=['For ' paramName ' ' int2str(forValues(i)) ': '];
   % use threshold at the previous point as starting value 
   % for the next point, provided it's not too large
   if isempty(v)
      startVal=InitialValue;
   else
      startVal=v(length(v));
   end;
   if exist('UpperLimit')
      if startVal > UpperLimit
         startVal=UpperLimit-Step;
      end;
   end;
   
   % get next threshold
   v=[v staircase(threshParamIndex,startVal,Step, ...
         NumReversals, AdditionalComment, LowerLimit, UpperLimit) ];
end;

ddeterm(sgridchan);

