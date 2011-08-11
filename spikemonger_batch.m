setpath;

rootdir = '/shub/experiments/data.expt34/split/';
%rootdir = './todo2/';
subdirs = [getfilelist(rootdir, 'P', 'prefix')];


% fprintf_title('subdirs:');
% for ii=1:L(subdirs)
%   fprintf_numbered(subdirs(ii).name, ii, L(subdirs));
% end

for ii=1:L(subdirs)
%try
  t1 = clock;
  fprintf_numbered(subdirs(ii).name,ii,L(subdirs),'title');
  %A1_convert_f32s(subdirs(ii).fullname);
  spikemonger(subdirs(ii).fullname);  
  fprintf_subtitle(['finished ' subdirs(ii).name ' successfully:  ' timediff(t1,clock)]);
%{
catch ME
  if isempty(ME.identifier)
    rethrow(ME);
  end
  fprintf_title(['ERROR WITH SUBDIR: ' subdirs(ii).name]);
  fprintf_bullet([ME.identifier '\n'],2);
  fprintf_bullet([ME.message '\n'],2);
  fprintf_bullet(['saving error as error.' subdirs(ii).name ...
		  '.mat\n'],2);
  save(['error.' subdirs(ii).name '.mat'],'ME','-v6');
end
%}
end 
