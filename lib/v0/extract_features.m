function varargout = extract_features(data)
  % features = extract_features(data)
  % features = extract_features(shapes)
  % [features shapes_aligned] = extract_features(...)
  %
  % takes a dataset, and computes a range of functions over the shapes.
  % These values locate each spike within a feature space. 
  %
  % As at v0.9.3.3, the features available are:
  %   - energy:       the variance of the signal
  %   - peakmax:      the maximum value of the signal
  %   - peakmin:      the minimum value of the signal
  %   - area_peak:    the area of the signal above y=0
  %   - area_valley:  the area of the signal below y=0
  %
  %   - derivative_max_positive:  the max +ve derivative of the signal
  %   - derivative_max_negative:  the max -ve derivative of the signal
  %   - derivative_max_absolute:  the max abs.derivative of the signal
  %   - derivative_sum_absolute:       the integral of the abs.derivative
  %
  %   - time:         the time at which the spike occurred
  %   - local_rate:   a coarse measure of the local firing rate
  %                     based on the ISI            
  %   - pca1-pca9:    projection along principal components 1-9
  
  % ======================
  % SPIKEMONGER v0.9.3.4
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)

  
  SKIP_ALIGNMENT = 0;
  
  
  
  if isnumeric(data)
    error('input:error','data needs to be a struct');
    %shapes = data;
  elseif isstruct(data)
    shapes = data.spikes.shapes;
  else
    error('input:error','data is wrong format');
  end

  % calculate features
    features.energy = var(shapes);  
      [features.peakmax features.peakmaxt] = max(shapes);
      [features.peakmin features.peakmint] = min(shapes);  
    features.area_peak    = sum(shapes .* (shapes>0));
    features.area_valley  = sum(shapes .* (shapes<0));
  
    features.time = data.spikes.presentation_order;
    
    local_rate = [NaN (1 ./ diff(data.spikes.t_absolute_ms))];
    local_rate([true ~(diff(data.spikes.sweep_id)==0)]) = NaN;
    local_rate( isnan(local_rate) ) = nanmedian(local_rate);
    features.local_rate = local_rate;
    
  % derivative features
    features.derivative_max_positive = max(diff(shapes));
    features.derivative_max_negative = max(-diff(shapes));
    features.derivative_max_absolute = max(abs(diff(shapes)));
    features.derivative_sum_absolute = sum(abs(diff(shapes)));

  % do pca
    if SKIP_ALIGNMENT
      for ii=1:9
        eval(['features.pca' num2str(ii) ' = 0*features.energy;']);   
      end
    else
      try
        sh = align_shapes(shapes,features);
        for ii=1:9
          eval(['features.pca' num2str(ii) ' = sh.pca_projection(' num2str(ii) ',:);']);   
        end
      catch
        fprintf('        * insufficient memory for alignment, ignoring\n');
        SKIP_ALIGNMENT = true;
        try
        for ii=1:9
          eval(['features.pca' num2str(ii) ' = 0*features.energy;']);   
        end
        catch
        end
      end
      
    end
  
  % parse varargout
  switch nargout
    case {0,1}
      varargout(1) = {features};
    case 2
      varargout(1) = {features};      
      if SKIP_ALIGNMENT
        varargout(2) = {shapes};
      else
      	varargout(2) = {sh.aligned};
      end
  end
  
  
end