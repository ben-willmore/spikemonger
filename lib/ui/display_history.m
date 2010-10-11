function display_history(history)

  fprintf_subtitle('history file:');
  
  for ii=1:L(history)
    % what was pressed
    action_keys = history{ii};
    
    % description
    switch action_keys{1}
      case 'm' % merge
        fprintf(['  [' n2s(ii) ']  m: merge clusters\n']);
        fprintf_bullet(['clusters:    ' n2s(cell2mat(action_keys(2:end))) '\n'],6);
        
      case 'd' % delete
        fprintf(['  [' n2s(ii) ']  d: delete a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        
      case 'c' % cleave
        fprintf(['  [' n2s(ii) ']  c: cleave a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        fprintf_bullet(['start time:  ' n2s(action_keys{3}) '\n'],6);
        fprintf_bullet(['end time:    ' n2s(action_keys{4}) '\n'],6);
        
      case 'i' % fix ISIs, <1ms
        fprintf(['  [' n2s(ii) ']  i: fix ISIs, < 1ms\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);

      case 'I' % fix ISIs, ~50Hz
        fprintf(['  [' n2s(ii) ']  i: fix ISIs, ~50Hz\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);        
        
      case 's' % save
        fprintf(['  [' n2s(ii) ']  s: save a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        
      case 'S' % save all
        fprintf(['  [' n2s(ii) ']  s: save all clusters\n']);
        
      case 0 % quit
        fprintf_bullet(['quit\n']);
    end
    
    fprintf('\n');
  end