function [SP, NP, TP, SP_std_error] = sahani_quick(data)
  % [SP, NP, TP] = sahani_quick(data)
  % [SP, NP, TP, SP_std_error] = sahani_quick(data)
  %
  % data must be N*T
  %   N = number of repeats
  %   T = number of time bins
  
  N = size(data, 1);  
  T = size(data, 2);
  
  % total power = average( power in each trial )
  TP = mean(var(data,[],2));
  
  % signal power
  SP = 1/(N-1) * (N * var(mean(data)) - TP);  
  if SP<0
    SP = nan;
  end
  
  % noise power
  NP = TP-SP;
  
  % standard error in estimate, if requested
  if nargout==4    
    
    % intermediate quantities
    mu_vector = mean(data)';
    mu_scalar = mean(mu_vector);

    noise_matrix = data - repmat(mu_vector', N, 1);  
    SIGMA = cov(noise_matrix);
    sigma_vector = mean(SIGMA)';
    sigma_scalar = mean(sigma_vector);

    term_11 = (mu_vector' * SIGMA * mu_vector) / (T^2);
    term_12 = -2 / T * mu_scalar * (sigma_vector' * mu_vector);
    term_13 = mu_scalar * sigma_scalar * mu_scalar;
    term_1 = 4 / N * (term_11 + term_12 + term_13);

    term_21 = trace(SIGMA * SIGMA) / (T^2);
    term_22 = -2 / T * (sigma_vector' * sigma_vector);
    term_23 = sigma_scalar^2;
    term_2 = 2 / (N * (N-1)) * (term_21 + term_22 + term_23);

    % calculate variance of estimator
    var_of_estimate = term_1 + term_2;
    % standard error
    SP_std_error = sqrt(var_of_estimate);
    
  else
    
    SP_std_error = nan;
    
  end
  
  
  
end
