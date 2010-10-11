function d=bwsrctof32(filename)

c=ddeinit('BrainWare32','Settings');
% Start conversation with Brainware on channel c.

d=[];

% for each .src file in fnames,
bwopen(filename);
% open the .src file in brainware
ddeexec(c,'export');
% export a .f32 file for each of the clusters in that file
a=ddereq(c,'info',[1 1]);
% make 'a' a matrix of the exported .f32 filenames.  Complete with folder paths.
ddeexec(c,'close');
% close the .src file in brainware.

x=find(a==10);
% make x a matrix of indexes in 'a' in which a carrier return is present.  10 must be code for a hard return.
% There is one hard return at the beginning and one after each .f32 file name.
for jj=1:length(x)-1,
    % for each f32 file,
    datum.fname=a(x(jj)+1:x(jj+1)-1);
    % Make datum.fname = field of the array 'datum', which is a string of the .f32 filename
    d=[d datum];
    % d.fname is now an array 'd' with feild 'fname' which contains the concatenated matrix of all the .f32
    % filenames, for all clusters and all .src files
end;


ddeterm(c);
% end conversation with brainware
