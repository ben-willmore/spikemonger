function writeBWVTfile(fname,traces,comments);
%
% function writeBWVTfile(fname,traces,comments);
%  writes BrainWare Voltage Trace file "fname" generated with BrainWare.
%  and generates lists of "traces" and "comments" which contain the 
%  data objects 
%

f=fopen(fname,'W');
if ~exist('comments'), 
    comments=[]; 
end;
for ii=1:length(traces),
    writeDAMArecord(f,traces(ii));
end;   
for ii=1:length(comments),
    writeCommentObj(f,comments(ii));
end;   
fclose(f);


function writeDAMArecord(f,data);
%********************************
fwrite(f,29123,'uint16'); % write  DAMA record id number 
fwrite(f,data.timeStamp,'float64');
fwrite(f,data.stimIndex,'int16');
writeStimObj(f,data.stim);
writeFloatSigObj(f,data.signal, data.samplePeriod);


function writeFloatSigObj(f,sig,samplePeriod);
%**********************************
fwrite(f,29122,'uint16'); % write ID number for nstim object
fwrite(f,samplePeriod,'float32'); 
fwrite(f,length(sig),'int32');
fwrite(f,sig,'float32');
% done writeFloatSigObj()

function writeStimObj(f,stim);
%****************************
% write stimulus object to file
fwrite(f,29109,'uint16'); % write ID number for nstim object
if isempty(stim),
    numParams=0 ;
else
    numParams=length(stim.paramVal);
end;
fwrite(f,numParams,'int16'); % write number of stimulus parameters
% write stimulus parameter names in turn
for ii=1:numParams,
    fwrite(f,1,'char'); % skip one byte
    fwrite(f,length(stim.paramName{ii}),'uint8'); % write length of next parameter name
    fwrite(f,stim.paramName{ii},'char')'; % write next parameter name 
end;
% finally write parameter values - an array of numParams 32-bit floating point numbers
if numParams > 0, fwrite(f,stim.paramVal,'float32'); end;
% done writeStimObj()


function comment=writeCommentObj(f,comment);
%**********************************
fwrite(f,29111,'uint16'); % write ID number for nstim object
fwrite(f,comment.timeStamp,'float64'); % write timeStamp (number of days since dec 30th 1899)
fwrite(f,length(comment.sender),'int16');
fwrite(f,comment.sender,'char');
fwrite(f,length(comment.text),'int16');
fwrite(f,comment.text,'char');
% done writeCommentObj()


