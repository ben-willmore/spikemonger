function data=readSRCfile_nodisp(fname)
%********************************
% function data=readSRCfile(fname);
%  reads Spike ReCording file "fname" generated with BrainWare.
%  and generates a structured array "data" which mimicks the 
%  data object hierarchy used by BrainWare to organise spike data internally
%
data=[];
f=fopen(fname,'r');
while ~feof(f)
    data=[data readDataObject(f)];
end;

fclose(f);

function dataObject=readDataObject(f)
%************************************

dataObject=[];
objId=fread(f,1,'uint16'); % get ID number for next data object
if isempty(objId),
    return;
end;

% 
% if sum(find(objId==[29115, 29082, 29083, 29084, 29110, 29109, 29091, 29116]))==0
%     disp(objId),
% end;

if ~isempty(objId) % i.e. while file f has not run to end of file
    switch objId
    case 29079, % Fixed length (40 time bin) action potential
        dataObject=readFixedLenSpike(f);
    case 29081, % Old style Fixed length (40 time bin) action potential
        dataObject=readOldFixedLenSpike(f);
    case 29115, % Variable length action potential
        dataObject=readVarLenSpike(f);
    case 29113; % display information object, 34 bytes wide - skip
        dataObject=[]; fread(f,34,'uint8'); 
    case 29100; % old style display information object, 4 bytes wide - skip
        dataObject=[]; fread(f,4,'uint8'); 
    case 29093; % old style data set collection, same as list
        dataObject=readList(f);
    case 29112; % data set collection with comments
        dataObject=readSetCollectionObject(f);
    case 29114; % variable ADperiod data set collection 
        dataObject=readVarPeriodSetCollectionObject(f);
    case 29117; % V8 data set collection 
        dataObject=readV8SetCollectionObject(f);
    case 29119; % sorter info object 
        dataObject=readSorterObject(f);
    case 29120; % version 9 set collection
        dataObject=readV9SetCollectionObject(f);            
    case 29121; % indexed data sweep 
        dataObject=readIndexedSweep(f);
    case 29110; % time stamped data sweep 
        dataObject=readTimeStampedSweep(f);
    case 29082; % normal data sweep 
        dataObject=readSweep(f);
    case 29106; % individual data set
        dataObject=readDatasetObj(f);
    case 29083; % collection (list) of data objects
        dataObject=readList(f);
    case 29107; % old style cluster with non-standard 6 byte float boundaries
        dataObject=readClusterV1(f);
    case 29116; % new style cluster with IEEE 4 byte float boundaries
        dataObject=readClusterV2(f);
    case 29084; % spike record (i.e. spike data for a cluster, but without cluster bounds
        dataObject=readSpkRec(f);
    case 29091; % collection of clusters - same structure as list
        dataObject=readList(f);
    case 29109; % stimulus descriptor object
        dataObject=readStimObj(f);
    case 29099; % old fashioned stimulus descriptor object
        dataObject=readOldStimObj(f);
    otherwise 
        % fclose(f);
        warning('data:unrecognised',['read unrecognized data object ID ' int2str(objId)]);
    end;
end; 
% done function readDataObject

function data=readV8SetCollectionObject(f)
%*************************************************
data=readVarPeriodSetCollectionObject(f);
peek=fread(f,1,'uint16');
fseek(f,-2,0);
if peek > 29000 % object id : read sorter as object 
    data.sortInfo=readDataObject(f);
else
    data.sortInfo=readSorter(f);
end;
dummy=fread(f,1,'int16');
% done function readV8SetCollectionObject

function data=readSorter(f)
%*************************************************
data.nTimeSlices=fread(f,1,'int16');
data.timeslice=[];
for ii=1:data.nTimeSlices,
    slice=[];
    fread(f,1,'int16');
    slice.maxValid=fread(f,1,'double');
    slice.nClust=fread(f,1,'int16');
    slice.cluster=[];
    for jj=1:slice.nClust,
        clust=[];
        dummy2=fread(f,1,'int16');
        clust.numChans=fread(f,1,'int16');
        clust.elliptic=fread(f,10*clust.numChans,'uint8'); % skip boolean values indicating elliptic feature boundary dimensions
        clust.boundaries=fread(f,20*clust.numChans,'float32'); % read boundaries
        slice.cluster=[slice.cluster, clust];
    end;
    data.timeslice=[data.timeslice, slice];
end;


function data=readSorterObject(f)
%*************************************************
atimezero=fread(f,1,'double');
data=readSorter(f);
data.timezero=atimezero;

function cluster=readSpkRec(f)
%********************************
fread(f,1,'uint16'); % skip two bytes
% read ID string (cluster 'name')
numChars=fread(f,1,'uint16');
anIDStr=fread(f,numChars,'char')';
cluster.IdString=char(anIDStr);
cluster.sweepLen=fread(f,1,'int32'); % sweep length in ms
cluster.respWin=fread(f,4,'int32'); % response and spon period boundaries
cluster.sweeps=readDataObject(f); % data sweeps
% done readSpkRec(f);

function data=readVarPeriodSetCollectionObject(f)
%*************************************************
anADperiod=fread(f,1,'float32'); % DA conversion clock period in microsec
data=readSetCollectionObject(f);
data.ADperiod=anADperiod;
% done function readVarPeriodSetCollectionObject

function data=readV9SetCollectionObject(f)
%*************************************************
data=readV8SetCollectionObject(f);
data.featureType=fread(f,1,'uint8'); 
data.goByClosestClusterCentre=fread(f,1,'uint8'); 
data.includeClusterBounds=fread(f,1,'uint8'); 
% done function readV9SetCollectionObject

function data=readSetCollectionObject(f)
%****************************************
data.NChannels=fread(f,1,'uint8'); % read number of electrode channels in set
data.sets=readList(f); % read individual datasets
data.side=char(fread(f,1,'char')); %#ok<FREAD> % read "side of brain" info
% read comments
numComments=fread(f,1,'int16');
data.comments=[];
for ii=1:numComments,
    data.comments=[data.comments readCommentObj(f)];
end;
% done function readSetCollectionObject

function aList=readList(f)
%**************************
numElements=fread(f,3,'int16'); %read three integers. 
% The 1st integer gives number of data sets. 
% (The others can be ignored).
aList=[];
for ii=1:numElements(1)
    % each element is read in turn by readDataObject() and appended to the list
    newElement=readDataObject(f);
    aList=[aList newElement];
end;


function set=readDatasetObj(f)
%****************************** 
% read and return the dataset object
set.stim=readDataObject(f); % read the stimulus for this set
set.unassignedSpikes=readDataObject(f); % read sweep collection of unassigned spikes
set.clusters=readDataObject(f); % read collection of spike clusters
set.sweepLen=fread(f,1,'int32'); % read sweep length for dataset
% done readDatasetObj()

function stim=readOldStimObj(f)
%****************************
stim.params=fread(f,14,'int16'); % these are the values for interval, light start, light len, ...

function stim=readStimObj(f)
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

function sweep=readTimeStampedSweep(f)
%*************************************
sweep.timeStamp=fread(f,1,'float64'); % read timeStamp (number of days since dec 30th 1899)
sweep.spikes=readList(f); % read spike list
% done readTimeStampedSweep(f);

function sweep=readIndexedSweep(f)
%*************************************
sweep.damaIndex=fread(f,1,'int32'); % read dama index (index of sweep in corresponding .dam file, if any)
sweep.timeStamp=fread(f,1,'float64'); % read timeStamp (number of days since dec 30th 1899)
sweep.spikes=readList(f); % read spike list
% done readIndexedSweep(f);

function sweep=readSweep(f)
%***************************
sweep.spikes=readList(f); % read spike list
% done readSweep(f);

function clusters=readClusters(f) %#ok<DEFNU>
%*********************************
objId=fread(f,1,'uint16');
if objId ~= 29091,
    error(['Trying to read data cluster collection but found bad object id: ' int2str(objId)]);
end;
numClust=fread(f,3,'int16'); % read three integers. 1st int is number of clusters.
clusters=[];  % initialise list of clusters
for ii=1:numClust;
    clusters=[clusters readCluster(f)]; % read individual clusters and add to list
end;
% done readClusters(f);

function cluster=readClusterV1(f)
%********************************
fread(f,1,'uint16'); % skip two bytes
% read ID string (cluster 'name')
numChars=fread(f,1,'uint16');
anIDStr=fread(f,numChars,'char')';
cluster.IdString=char(anIDStr);
cluster.sweepLen=fread(f,1,'int32'); % sweep length in ms
cluster.respWin=fread(f,4,'int32'); % response and spon period boundaries
cluster.sweeps=readDataObject(f); % data sweeps
% cluster boundaries are stored in 48-bit floating point numbers which is not supported in Matlab - skip
fread(f,18*6,'uint8'); % skip boundaries
cluster.elliptic=fread(f,9,'uint8'); % skip boolean values indicating elliptic feature boundary dimensions
% done readClusterV1(f);

function cluster=readClusterV2(f)
%********************************
fread(f,1,'uint16'); % skip two bytes
% read ID string (cluster 'name')
numChars=fread(f,1,'uint16');
anIDStr=fread(f,numChars,'char')';
cluster.IdString=char(anIDStr);
cluster.sweepLen=fread(f,1,'int32'); % sweep length in ms
cluster.respWin=fread(f,4,'int32'); % response and spon period boundaries
cluster.sweeps=readDataObject(f); % data sweeps
% cluster boundaries stored in IEEE 32-bit floats
cluster.boundaries=fread(f,18,'float32'); % read boundaries
cluster.elliptic=fread(f,9,'uint8'); % skip boolean values indicating elliptic feature boundary dimensions
% done readClusterV2(f);

function spike=readOldFixedLenSpike(f)
%***********************************
spike.time=fread(f,1,'int32')/25; % read spike time stamp in ms since start of sweep 
spike.shape=fread(f,40,'int8'); % read spike shape;

function spike=readFixedLenSpike(f)
%***********************************
spike.time=fread(f,1,'float32'); % read spike time stamp in ms since start of sweep
spike.shape=fread(f,40,'int8'); % read spike shape;
spike.trig2=fread(f,1,'uint8'); % point of return to noise
% done readFixedLenSpike

function spike=readVarLenSpike(f)
%**********************************
numPts=fread(f,1,'uint8');
spike.time=fread(f,1,'float32'); % read spike time stamp in ms since start of sweep
spike.shape=fread(f,numPts,'int8'); % read spike shape;
spike.trig2=fread(f,1,'uint8'); % point of return to noise
% done readVarLenSpike

function comment=readCommentObj(f)
%**********************************
comment.timeStamp=fread(f,1,'float64'); % read timeStamp (number of days since dec 30th 1899)
numChars=fread(f,1,'int16');
comment.sender=char(fread(f,numChars,'char')');
numChars=fread(f,1,'int16');
comment.text=char(fread(f,numChars,'char')');
% done readCommentObj()
