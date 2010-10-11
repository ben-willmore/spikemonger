function [traces, comments]=readBWVTfile(fname);
%
% function [traces, comments]=readBWVTfile(fname);
%  reads BrainWare Voltage Trace file "fname" generated with BrainWare.
%  and generates lists of "traces" and "comments" which contain the 
%  data objects 
%

traces=[];
comments=[];
f=fopen(fname,'r');
while ~feof(f)

    dataObject=[];
    objId=fread(f,1,'uint16'); % get ID number for next data object
    if isempty(objId),
        fclose(f);
        return;
    end;

    if ~isempty(objId) % i.e. while file f has not run to end of file
        switch objId
            case 29123, % DAMA record
                dataObject=readDAMArecord(f);
                traces=[traces dataObject];
            case 29111, % Comment
                dataObject=readCommentObj(f);
                comments=[comments dataObject];
          otherwise              
                % fclose(f);
                %warning(['read unrecognized data object ID '
                %int2str(objId)]);
        end;
    end;
end;
fclose(f);


function data=readDAMArecord(f);
%********************************
data.timeStamp=fread(f,1,'float64');
data.stimIndex=fread(f,1,'int16');
data.stim=readDataObject(f);
asig=readDataObject(f);
data.samplePeriod=asig.samplePeriod;
data.signal=asig.signal;

function dataObject=readDataObject(f);
%************************************
dataObject=[];
objId=fread(f,1,'uint16'); % get ID number for next data object

if ~isempty(objId) % i.e. while file f has not run to end of file
  switch objId
    case 29109; % stimulus descriptor object
        dataObject=readStimObj(f);
    case 29099; % old fashioned stimulus descriptor object
        dataObject=readOldStimObj(f);
    case 29122; % floatSig object
        dataObject=readFloatSigObj(f);
    case 29124; % intSig object
        dataObject=readIntSigObj(f);
    otherwise 
        % fclose(f);
        warning(['read unrecognized data object ID ' int2str(objId)]);
    end;
end; 
% done function readDataObject

function stim=readOldStimObj(f);
%****************************
stim.params=fread(f,14,'int16'); % these are the values for interval, light start, light len, ...

function stim=readStimObj(f);
%****************************
% read a stimulus object from file
stim.numParams=fread(f,1,'int16'); % read number of stimulus parameters
stim.paramName=[]; % initialise list of parameter names
% read stimulus parameter names in turn
for ii=1:stim.numParams,
    fread(f,1,'char'); % skip one byte
    paramNameLen=fread(f,1,'uint8'); % read length of next parameter name
    nextName=fread(f,paramNameLen,'char')'; % read next parameter name 
    nextName=cellstr(char(nextName));% ... convert to string
    stim.paramName=[stim.paramName, nextName]; % ...and add it to the list of parameter names
end;
% finally read parameter values - an array of numParams 32-bit floating point numbers
stim.paramVal=fread(f,stim.numParams,'float32');
% done readStimObj()

function comment=readCommentObj(f);
%**********************************
comment.timeStamp=fread(f,1,'float64'); % read timeStamp (number of days since dec 30th 1899)
numChars=fread(f,1,'int16');
comment.sender=char(fread(f,numChars,'char')');
numChars=fread(f,1,'int16');
comment.text=char(fread(f,numChars,'char')');
% done readCommentObj()

function sig=readFloatSigObj(f);
%**********************************
sig.samplePeriod=fread(f,1,'float32'); 
length=fread(f,1,'int32');
sig.signal=fread(f,length,'float32');
% done readFloatSigObj()

function sig=readIntSigObj(f);
%**********************************
sig.samplePeriod=fread(f,1,'float32'); 
length=fread(f,1,'int32');
sig.signal=fread(f,length,'int16');
% done readFloatSigObj()
