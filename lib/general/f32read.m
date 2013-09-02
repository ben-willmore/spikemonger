function data = f32read(filename)

tempfilename = '';
if strcmp(filename(end-2:end), '.gz')
	filenames = gunzip(filename, tempdir);
	filename = filenames{1};
	tempfilename = filename;
elseif strcmp(filename(end-3:end), '.zip')
	filenames = unzip(filename, tempdir);
	filename = filenames{1};
	tempfilename = filename;
end

f = fopen(filename,'r');
if (f==-1)
  error('Could not open file');
else
  data = fread(f,Inf,'float32');
  fclose(f);
end

if ~isempty(tempfilename)
	delete(tempfilename);
end
