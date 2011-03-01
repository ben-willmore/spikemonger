function v = sahani_variance_explainable(data,tt)
% v = sahani_variance_explainable(data,tt)
%
% data: as output by spikemonger
% tt:   edges of bins for histogram


% initialise structure
v = struct;
v.tt = tt;
v.tc = midpoints(tt);

[v.individual.total_power ...
  v.individual.signal_power ...
  v.individual.noise_power ...
  v.individual.percentage_signal ...
  v.individual.percentage_noise ...
  v.individual.noise_ratio ...
  v.individual.scale_performance_factor ...
  ] = IA(nan(1,L(data)));


%% calculate for each stimulus
% ================================

for ii=1:L(data)
  % number of repeats
  N = L(data(ii).repeats);
  if N<=1
    v.individual.total_power(ii) = nan;
    v.individual.signal_power(ii) = nan;
    v.individual.noise_power(ii) = nan;
    v.individual.percentage_signal(ii) = nan;
    v.individual.percentage_noise(ii) = nan;
    v.individual.noise_ratio(ii) = Inf;
    v.individual.scale_performance_factor(ii) = nan;
    v.individual.stim_params(ii) = data(ii).stim_params;
    continue;
  end
  
  % histogram
  h = zeros(N, L(tt)-1);
  for jj=1:N
    try
      h(jj,:) = histc_nolast(data(ii).repeats(jj).t,tt);
    catch
    end
  end
  
  % calculate v explainable
  v.individual.total_power(ii) = mean(var(h));
  v.individual.signal_power(ii) = 1/(N-1) * (N * var(mean(h)) - mean(var(h,[],2)));
  v.individual.noise_power(ii) = v.individual.total_power(ii) - v.individual.signal_power(ii);
  v.individual.noise_ratio(ii) = v.individual.noise_power(ii) / v.individual.signal_power(ii);
  v.individual.scale_performance_factor(ii) = v.individual.total_power(ii) ...
      / v.individual.signal_power(ii);
try
  v.individual.stim_params(ii) = data(ii).stim_params;
catch
end
end

v.individual.percentage_signal = v.individual.signal_power ./ v.individual.total_power * 100;
v.individual.percentage_noise  = v.individual.noise_power ./ v.individual.total_power * 100;

v.individual.percentage_noise(v.individual.percentage_signal <= 0) = 100;
v.individual.percentage_signal(v.individual.percentage_signal <= 0) = 0;

%% calculate for overall dataset
% ===============================

v.total_power = sum(v.individual.total_power);
v.signal_power = sum(v.individual.signal_power);
v.noise_power = v.total_power - v.signal_power;
v.percentage_signal = v.signal_power / v.total_power * 100;
v.percentage_noise  = v.noise_power  / v.total_power * 100;
v.noise_ratio = v.noise_power / v.signal_power;
v.scale_performance_factor = v.total_power / v.signal_power;

if v.signal_power < 0
  v.signal_power = 0;
  v.noise_power = v.total_power;
  v.noise_ratio = Inf;
  v.scale_performance_factor = nan;
  v.percentage_signal = 0;
  v.percentage_noise  = 100;
end

end