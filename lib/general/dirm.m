function dirm(path)
  % dirm
  % dirm(path)
  
  if nargin==0
    path = [pwd '/'];
  else
    path = fixpath(path);
  end

  % old version
  %{
  fprintf('\n')
  !ls -1 *.m | grep -v setpath | sed -n 's:\.m::p'
  fprintf('\n')
  %}

  % files
  ft = dir([path '*.m']);

  % filter
  for ii=1:L(ft)
    ft(ii).tokeep = isempty(strfind(ft(ii).name,'setpath'));
  end
  ft = ft([ft.tokeep]);

  % needs a new line?
  for ii=1:L(ft)
    n = ft(ii).name(1);
    ft(ii).iscapital = strcmp(upper(n),n);
    ft(ii).newline   = false;
  end

  ft(1).newline = true;
  if ~all([ft.iscapital])
    first_noncapital = find(~[ft.iscapital],1,'first');
    ft(first_noncapital).newline = true;
  end

  for ii=2:L(ft)
    n1 = ft(ii).name(1);
    n0 = ft(ii-1).name(1);
    if ft(ii).iscapital & ft(ii-1).iscapital & ~strcmp(n0,n1)
      ft(ii).newline = true;
    end
  end

  % print
  delim_length = max(Lincell({ft.name}) + 4);
  delim = [repmat('-',1,delim_length) '\n'];
  fprintf('\n');
  for ii=1:L(ft)
    if ft(ii).newline
      fprintf(delim);
    end
    fprintf(['  ' strip_suffix(ft(ii).name) '\n']);
  end
  fprintf(delim);
  fprintf('\n');