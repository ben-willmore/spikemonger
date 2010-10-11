function c=bwopen(fileName);

if iscellstr(fileName) 
   fileName=char(fileName);
end;

L=length(fileName);
if fileName(L-2:L)=='f32'
   L=find(fileName=='-');
   fileName=[fileName(1:L-1) '.src'];
end;
if fileName(L-2:L)=='fc3'
   L=find(fileName=='-');
   fileName=[fileName(1:L-1) '.src'];
end;
if fileName(L-2:L)=='fc4'
   L=find(fileName=='-');
   fileName=[fileName(1:L-1) '.src'];
end;
if fileName(L-2:L)=='dsc'
   L=find(fileName=='-');
   fileName=[fileName(1:L-1) '.src'];
end;
if fileName(end-3)~='.' fileName=[fileName '.src']; end;

c=ddeinit('brainware32','settings');
if c==0 
   dos('c:\jan\wphysio6\brainware32.exe &');
   c=ddeinit('brainware32','settings');
end;
ddeexec(c,['open ' fileName]); ddeterm(c);
c=ddeinit('brainware32','messages');
a=ddereq(c,'messagetext',[1,2]);
if nargout==0
    ddeterm(c);
    c=0;
end;