function fixV911betaBWVTfiles(fname);

% BW version 9.11 beta sometimes wrote mutiple (incomplete) copies of the
% dama buffers. Multiple copies will have identical timestamps and appear
% back to back. Therefore, if there are identical timestamps, only keep the
% later of the two records in the list.
[a, c]=readBWVTfile(fname);
ii=1;
while ii<length(a),
    if isempty(a(ii).stim)
        a(ii)=[];
    end;
    if a(ii+1).timeStamp==a(ii).timeStamp,
        a(ii)=[];
    else
        ii=ii+1;
    end;
end;
writeBWVTfile(fname,a,c);