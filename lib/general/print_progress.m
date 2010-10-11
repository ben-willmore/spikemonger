function progress = print_progress(ii,max_ii,old_progress)
  % progress = print_progress(ii,maxii,old_progress)
  %
  % prints a series of 10 dots as a text-based alternative to a progress
  % bar

  progress = floor(10*ii/max_ii);
  if progress > old_progress
    fprintf('.');
  end
  
end