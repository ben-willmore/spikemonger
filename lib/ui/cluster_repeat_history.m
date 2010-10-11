function C = cluster_repeat_history(C,history,dirs,cols)
  % C = cluster_repeat_history(C,history,dirs,cols)

  for ii=1:L(history)
    % what was pressed
    action_keys = history{ii};
    
    % description
    switch action_keys{1}
      case 'm' % merge
        fprintf(['  [' n2s(ii) ']  m: merge clusters\n']);
        fprintf_bullet(['clusters:    ' n2s(cell2mat(action_keys(2:end))) '\n'],6);
        C = cluster_merge(C,cell2mat(action_keys(2:end)));
        
      case 'd' % delete
        fprintf(['  [' n2s(ii) ']  d: delete a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        C = cluster_delete(C, action_keys{2});
        
      case 'c' % cleave
        fprintf(['  [' n2s(ii) ']  c: cleave a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        fprintf_bullet(['start time:  ' n2s(action_keys{3}) '\n'],6);
        fprintf_bullet(['end time:    ' n2s(action_keys{4}) '\n'],6);
        C = cluster_cleave(C,action_keys{2},action_keys{3},action_keys{4},dirs);
        
      case 'i' % fix ISIs, <1ms
        fprintf(['  [' n2s(ii) ']  i: fix ISIs, < 1ms\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        C = cluster_fix_isis_1ms(C,action_keys{2},dirs,cols,'force');        

      case 'I' % fix ISIs, ~50Hz
        fprintf(['  [' n2s(ii) ']  i: fix ISIs, ~50Hz\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);        
        C = cluster_fix_isis_50Hz_2(C,action_keys{2},dirs,cols,action_keys{3});
        
      case 's' % save
        fprintf(['  [' n2s(ii) ']  s: save a cluster\n']);
        fprintf_bullet(['cluster:     ' n2s(action_keys{2}) '\n'],6);
        C = cluster_save(C,action_keys{2},dirs);
        
      case 'S' % save all
        fprintf(['  [' n2s(ii) ']  s: save all clusters\n']);
        C = cluster_save(C,1:L(C.fsp),dirs);        
        
    end

  end
%%