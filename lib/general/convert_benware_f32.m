function convert_benware_f32(dirs, file, sweep)
% convert_benware_f32(dirs, file, sweep)

% sample rate
dt = 0.040959999071638; % ms
fs = 1000/dt;           % Hz

% ensure dirs structure is prepared
dirs = fix_dirs_struct(dirs);

% does the source file exist?
if ~exist(file.fullname,'file')
  error('file:error','file does not exist');
end

% import
fid = fopen(file.fullname);
signal = fread(fid, inf, 'float32');
fclose(fid);

% check that it is the right length
correct_length = sweep.sweepLen.samples;
actual_length = L(signal);
if ~(correct_length == actual_length)
  error('file:error', 'file is the wrong length');
end

% target file
swf = struct;
swf.f32_source = file.prefix;
swf.timestamp = datestr(sweep.timeStamp, 'yyyymmdd-HHMMSSFFF');

% does the destination file exist?
if does_sweep_file_exist(dirs, swf, 'filtered_signal')
  fprintf('       * (already done)\n');
  return
end

% sweep params
sweep_params = struct;
sweep_params.all.names  = sweep.stimInfo.stimGridTitles;
sweep_params.all.values = sweep.stimInfo.stimParameters;

fields = sweep_params.all.names;
for ff=1:L(fields)
  fieldname = fields{ff};
  fieldname(fieldname==' ') = '_';
  sweep_params.(fieldname) = sweep_params.all.values(ff);
end
sweep_params.length_signal_smp = L(signal);
sweep_params.length_signal_ms  = L(signal) * dt;
save_sweep_file(dirs, swf, sweep_params, 'sweep_params');

% filtered signal
filtered_signal = bandpass_for_spikes(signal, fs);
save_sweep_file(dirs, swf, filtered_signal, 'filtered_signal');