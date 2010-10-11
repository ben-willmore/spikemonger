function new_sm_version
  
  % get current version
    v.str = get_sm_version();
    v.n   = version_str2num(v.str);
    v(2).n  = v(1).n            + [0 0 0 1];
    v(3).n  = [v(1).n(1:3) 0]   + [0 0 1 1];
    v(4).n  = [v(1).n(1:2) 0 0] + [0 1 0 1];
    v(5).n  = [v(1).n(1) 0 0 0] + [1.0.0.19];


    for ii=2:5
      v(ii).str = [num2str(v(ii).n(1)) '.' num2str(v(ii).n(2)) '.' num2str(v(ii).n(3)) '.' num2str(v(ii).n(4))];
    end
        
  % get date
    olddate = get_sm_date;
    newdate = date;

    
  % ask for preferred new version
    fprintf([...
      '===================================\n'...
      ' CURRENT VERSION:\n'...
      '     ' v(1).str '\n'...
      '===================================\n'...
      ' NEW VERSION: \n'...
      '   [1]: ' v(2).str '\n'...
      '   [2]: ' v(3).str '\n'...
      '   [3]: ' v(4).str '\n'...
      '   [4]: ' v(5).str '\n'...
      ' \n'...
      '   [0]: cancel \n'...
      '===================================\n'...      
      ]);
    todo = demandnumberinput('       ----> ',0:4);
    
  % enact
  switch todo
    case 0
      return;
    otherwise
      vnew = struct;
      vnew.n    = v(todo+1).n;
      vnew.str  = v(todo+1).str;

      % update version names
        eval(['!sed -i -e ''s/' v(1).str '/' vnew.str '/'' *.m']);
        eval(['!sed -i -e ''s/' olddate '/' newdate '/'' *.m']);
        subdirs = dir('./*');
        subdirs = subdirs([subdirs.isdir]);
        subdirs = subdirs(3:end);
	for ii=1:L(subdirs)
	  switch subdirs(ii).name
	    case {'old.disabled','test'}
	     continue;
	   otherwise	    
	    try
	    eval(['!sed -i -e ''s/' v(1).str '/' vnew.str '/'' ' subdirs(ii).name '/*.m']);      
      eval(['!sed -i -e ''s/' olddate '/' newdate '/'' ' subdirs(ii).name '/*.m']);            
	    catch
	    end
	  end
	end


      % make new subdir
        eval(['!mkdir old.disabled/v' vnew.str]);
      % copy contents
        eval(['!cp * old.disabled/v' vnew.str]);
        subdirs = dir('./*');
        subdirs = subdirs([subdirs.isdir]);
        subdirs = subdirs(3:end);
        for ii=1:L(subdirs)
          switch subdirs(ii).name
            case {'old.disabled','test'}
              continue;
            otherwise
              eval(['!cp -R ./' subdirs(ii).name ' old.disabled/v' vnew.str '/']);
          end
        end
  end      
      
  
    % add changelog description
    fprintf(['\n'...
      '===================================\n'...
      ' ENTER CHANGELOG DESCRIPTION:\n'...
      '===================================\n'...
      ]);
    changelogstr = cell(1,1);
    ii=1;
    while 1
      changelogstr{ii} = input('       ----> ','s');
      if isempty(changelogstr{ii})
        break;
      end
      ii=ii+1;
    end
        
    fid = fopen('CHANGELOG','a');
    fprintf(fid,[...
      '\n\n'...
      'v' vnew.str '\n'...
      '-----------------------\n']);
    for ii=1:(L(changelogstr)-1)
      fprintf(fid,['  - ' changelogstr{ii} '\n']);
    end
    fclose(fid);
  
   
  
  
  
  
      
end   


%% ==========================================
% ===========================================      
function n = version_str2num(str)
  dotpos = strfind(str,'.');
  n = [...
    str2num( str(1:(dotpos(1)-1)) ), ...
    str2num( str((dotpos(1)+1):(dotpos(2)-1)) ), ...
    str2num( str((dotpos(2)+1):(dotpos(3)-1)) ), ...    
    str2num( str((dotpos(3)+1):L(str)) )];    
end