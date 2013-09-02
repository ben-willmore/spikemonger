function f32write(data, filename, compress)

if ~exist('compress', 'var')
  compress = false;
end

f = fopen(filename,'w');
if (f==-1)
  error('Could not open file');
else
  fwrite(f, data, 'float32');
  fclose(f);
end

if compress
  gzip(filename);
  delete(filename);
end
