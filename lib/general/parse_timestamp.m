function t = parse_timestamp(ts,type)
  % PARSE_TIMESTAMP
  %  parses a delphi timestamp, as used by Brainware
  %
  % t = parse_timestamp(ts)
  % t = parse_timestamp(ts,'str')
  
  t = datevec(datenum([1899 12 30+ts 0 0 0]));
  
  if nargin==2
    if isequal(type,'str')
      %t = datestr(t,'yyyy-mm-dd.HH:MM:SS.FFF');
      t = datestr(t,'yyyymmdd-HHMMSSFFF');
    end
  end
  
