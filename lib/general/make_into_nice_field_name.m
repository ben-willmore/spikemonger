function str = make_into_nice_field_name(str)
  % str = make_into_nice_field_name(str)
  
  % convert any crappy characters into "_"
    for ii=1:L(str)

      if isletter(str(ii))
        continue;
      end

      if isstrprop( str(ii), 'punct' )
        str(ii) = '_';
      end

      if strcmp(str(ii),' ')
        str(ii) = '_';
      end

      if strcmp(str(ii),'\')
        str(ii) = '_';
      end

    end
  
  % remove prefixual or suffixual "_"s
    while ( strcmp(str(1),'_') & L(str)>1 )
      str = str(2:end);
    end

    while ( strcmp(str(end),'_') & L(str)>1 )
      str = str(1:(end-1));
    end
    
  % remove multiple consecutive "_"s
    while ~isempty( strfind(str,'__') )
      loc = pick( strfind(str,'__'), 1);
      str = str([1:loc (loc+2):end]);
    end
    
end