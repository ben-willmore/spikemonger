function prefix = get_feature_prefix(features)
  % prefix = get_feature_prefix(features)
  %
  % Parses the list of features into a string sequence
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)


  prefix = [];
  
  for ii=1:L(features)
    switch features{ii}
      case 'energy'
        prefix = [prefix 'A'];
      case 'peakmax'
        prefix = [prefix 'B'];
      case 'peakmin'
        prefix = [prefix 'C'];
      case 'area_peak'
        prefix = [prefix 'D'];
      case 'area_valley'
        prefix = [prefix 'E'];
        
      case 'derivative_max_positive'
        prefix = [prefix 'F'];
      case 'derivative_max_negative'
        prefix = [prefix 'G'];
      case 'derivative_max_absolute'
        prefix = [prefix 'H'];
      case 'derivative_sum_absolute'
        prefix = [prefix 'I'];
        
      case 'pca1'
        prefix = [prefix '1'];
      case 'pca2'
        prefix = [prefix '2'];
      case 'pca3'
        prefix = [prefix '3'];
      case 'pca4'
        prefix = [prefix '4'];
      case 'pca5'
        prefix = [prefix '5'];
      case 'pca6'
        prefix = [prefix '6'];
      case 'pca7'
        prefix = [prefix '7'];
      case 'pca8'
        prefix = [prefix '8'];
      case 'pca9'
        prefix = [prefix '9'];
      case 'time'
        prefix = [prefix 'T'];
      case 'local_rate'
        prefix = [prefix 'R'];
    end
  end
  
  prefix = sort(prefix);
  
end