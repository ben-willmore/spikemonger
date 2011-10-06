function todo = request_action_main(n,dirs)
  % todo = request_action_main(n)

todo = {};

% title
clc;
fprintf_title(['[' n2s(n.c) ' clusters]  from  ' escape_slash(dirs.root)]);

% options
fprintf_bullet(['[0]:   close all plots\n']);
fprintf('\n');
fprintf_bullet(['[1]:   plot whole dataset\n']);
fprintf_bullet(['[2]:   plot single cluster\n']);
fprintf_bullet(['[3]:   plot cluster comparison\n']);
fprintf_bullet(['[p]:   close and replot all\n']);
fprintf_bullet(['[P]:   special plots\n']);
fprintf('\n');
fprintf_bullet(['[m]:   merge clusters\n']);
fprintf_bullet(['[d]:   delete a cluster\n']);
fprintf_bullet(['[c]:   cleave a cluster\n']);
fprintf_bullet(['[C]:   cleave out a cluster\n']);
fprintf('\n');
fprintf_bullet(['[i]:   fix cluster ISIs --  < 1 ms\n']);
fprintf_bullet(['[I]:   fix cluster ISIs --  50 Hz\n']);
fprintf_bullet(['[J]:   fix cluster ISIs --  100 Hz\n']);
fprintf('\n');
fprintf_bullet(['[s]:   save a cluster\n']);
fprintf_bullet(['[S]:   save all clusters\n']);
fprintf('\n');
fprintf_bullet(['[u]:   undo\n']);
fprintf_bullet(['[!]:   start over again\n']);
fprintf_bullet(['[h]:   view history\n']);
fprintf_bullet(['[H]:   continue from another history file\n']);
fprintf_bullet(['[k]:   keyboard mode\n']);
fprintf('\n');
fprintf_bullet(['[Q]:   quit\n']);
fprintf('\n');

todo{1} = demandinput('     >>> ',{'0','1','2','3','m','d','c','C','i','I','J','s','S','u','!','h','H','Q','k','p','P'});


% response
switch todo{1}
  
  case '1' % plot all
    fprintf_subtitle('plot whole dataset');
    fprintf_bullet(['[1]:  plot featurespace\n']);
    fprintf('\n');
    fprintf_bullet(['[2]:  plot waveforms\n']);    
    fprintf_bullet(['[3]:  plot PSTHs\n']);
    fprintf_bullet(['[4]:  plot ISIs\n']);
    fprintf_bullet(['[5]:  plot time course\n']);
    fprintf_bullet(['[6]:  plot triggers\n']);    
    fprintf('\n');
    fprintf_bullet(['[9]:  plot 2-6\n']);
    fprintf_bullet(['[0]:  cancel\n']);
    fprintf('\n');
    
    todo{2} = demandnumberinput('     >>> ',[1:5 0 9]);
    if todo{2}==0, todo = []; end
    return;
    
  case '2' % plot single
    fprintf_subtitle('plot single cluster');
    fprintf_bullet(['[1]:  plot featurespace\n']);
    fprintf_bullet(['[2]:  plot waveforms\n']);
    fprintf_bullet(['[3]:  plot PSTH\n']);
    fprintf_bullet(['[4]:  plot ACG\n']);
    fprintf_bullet(['[5]:  plot time course\n']);
    fprintf_bullet(['[6]:  plot triggers\n']);
    fprintf('\n');
    fprintf_bullet(['[7]:  plot raster\n']);
    fprintf('\n');
    fprintf_bullet(['[9]:  plot 2-6\n']);
    fprintf_bullet(['[0]:  cancel\n']);
    fprintf('\n');
    todo{2} = demandnumberinput('     >>> ',[1:7 0 9]);
    if todo{2}==0, todo = []; return; end
    todo{3} = demandnumberinput('\nWhich cluster?  >>> ', 0:n.c);
    if todo{3}==0, todo = []; end
    return;
      
  case '3' % plot comparison
    fprintf_subtitle('plot cluster comparison');
    fprintf_bullet(['[1]:  plot featurespace\n']);
    fprintf_bullet(['[2]:  plot waveforms\n']);
    fprintf_bullet(['[3]:  plot PSTHs\n']);
    fprintf_bullet(['[4]:  plot ISIs\n']);
    fprintf_bullet(['[5]:  plot time course\n']);
    fprintf_bullet(['[6]:  plot triggers\n']);
    fprintf('\n');
    fprintf_bullet(['[7]:  plot fsp separation\n']);
    fprintf_bullet(['[8]:  plot cross-correlogram\n']);
    fprintf('\n');
    fprintf_bullet(['[9]:  plot 2-6\n']);
    fprintf_bullet(['[0]:  cancel\n']);
    fprintf('\n');
    todo{2} = demandnumberinput('     >>> ',[1:6 0 7 8 9]);
    if todo{2}==0, todo = []; return; end
    still_available = 0:n.c;
    todo{3} = demandnumberinput('\nWhich cluster 1?  >>> ', [still_available 99]);
    if todo{3}==0, todo = []; return; end
    if todo{3}==99, todo = [todo{1} todo{2} map_to_array(@(x) x, 1:n.c)]; return; end
    still_available = setdiff(still_available, todo{3});
    todo{4} = demandnumberinput('\nWhich cluster 2?  >>> ', still_available);    
    if todo{4}==0, todo = []; return; end    
    still_available = setdiff(still_available, todo{4});
    toloop = true; todo_ii = 5;
    while toloop
      todo{todo_ii} = demandnumberinput(['\nWhich cluster ' n2s(todo_ii-2) '?  (0 if no more) >>> '], still_available);
      if todo{todo_ii}==0, todo = todo(1:(todo_ii-1)); toloop = false; break; end
      still_available = setdiff(still_available, todo{todo_ii});
      todo_ii = todo_ii+1;
    end
    return;
    
  case 'P' % special plots
    fprintf_subtitle('special plots');
    fprintf_bullet('[1]:  STRF for ctuning.drc data\n');    
    fprintf_bullet('[2]:  STRF for CRF04 data\n');
    fprintf('\n');
    fprintf_bullet(['[0]:  cancel\n']);
    fprintf('\n');
    todo{2} = demandinput('     >>> ',['0', '1', '2']);
    if isequal(todo{2},'0'), todo = []; return; end
    return;
    
  case 'm' % merge
    todo{2} = demandnumberinput('\nWhich cluster 1?  >>> ', 0:n.c);
      if todo{2}==0, todo = []; return; end
      still_available = setdiff(0:n.c, todo{2});
    todo{3} = demandnumberinput('\nWhich cluster 2?  >>> ', still_available);
      if todo{3}==0, todo = []; return; end
      still_available = setdiff(still_available, todo{3});
    toloop = true; todo_ii = 4;
    while toloop
      todo{todo_ii} = demandnumberinput(['\nWhich cluster ' n2s(todo_ii) '?  (0 if no more) >>> '], still_available);
      if todo{todo_ii}==0, todo = todo(1:(todo_ii-1)); toloop = false; break; end
      still_available = setdiff(still_available, todo{todo_ii});
      todo_ii = todo_ii+1;
    end
    return;
      

  case {'d','i','I','J','s'} % delete / fix-ISI / save
    todo{2} = demandnumberinput('\nWhich cluster?  >>> ', 0:n.c);
    if todo{2}==0, todo = []; return; end
    return; 
    
  case 'c' % cleave
    todo{2} = demandnumberinput('\nWhich cluster?  >>> ', 0:n.c);
    if todo{2}==0, todo = []; return; end
    todo{3} = demandnumberinput(['\nKeep from what sweep?  (1 - ' n2s(n.sweeps) ')  >>> '], 1:n.sweeps);
    if todo{3}==0, todo = []; return; end
    todo{4} = demandnumberinput(['\nKeep until what sweep?  (' n2s(todo{3}) ' - ' n2s(n.sweeps) ')  >>> '], todo{3}:n.sweeps);
    if todo{4}==0, todo = []; return; end    

  case 'C' % cleave out
    todo{2} = demandnumberinput('\nWhich cluster?  >>> ', 0:n.c);
    if todo{2}==0, todo = []; return; end
    todo{3} = demandnumberinput(['\Delete from what sweep?  (1 - ' n2s(n.sweeps) ')  >>> '], 1:n.sweeps);
    if todo{3}==0, todo = []; return; end
    todo{4} = demandnumberinput(['\Delete until what sweep?  (' n2s(todo{3}) ' - ' n2s(n.sweeps) ')  >>> '], todo{3}:n.sweeps);
    if todo{4}==0, todo = []; return; end    
    
  case '!' % start over again
    to_restart = demandinput(['\n\nAre you sure? This will undo everything you have done.\n' ...
                  '        [yes/no]   >>>  '], {'yes','no'});
    if ~isequal(to_restart,'yes')
      todo = [];
    end
      
  case 'Q' % start over again
    to_quit = demandinput(['\n\nAre you sure? This will quit. Quit quit.\n' ...
                  '        [yes/no]   >>>  '], {'yes','no'});
    if ~isequal(to_quit,'yes')
      todo = [];
    end
    
  case 'H' % repeat history
    history = pickdir_for_history_recovery(dirs);
    if isequal(history,[])
      todo = [];
      return;
    end
    display_history(history);
    max_steps = demandnumberinput('\nRepeat history up to where?   >>> ', 0:L(history));
      if max_steps==0, todo = []; return; end
    to_restart = demandinput(['\n\nAre you sure? This will start a new session.\n' ...
                  '        [yes/no]   >>>  '], {'yes','no'});
    if ~isequal(to_restart,'yes')
      todo = [];
    end
    todo{2} = history(1:max_steps);
     
    
end