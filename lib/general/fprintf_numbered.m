function fprintf_numbered(str,count,total_count,type)
  % fprintf_numbered(str,count,total_count)
  % fprintf_numbered(str,count,total_count,'subtitle')
  % fprintf_numbered(str,count,total_count,'title')
  % 
  % prints str as follows:
  %
  % [1/200]:  str
  
  strfull = ['[' n2s(count) '/' n2s(total_count) ']:   ' str];
  if nargin==3
    fprintf([strfull '\n']);
  else switch type %#ok<ALIGN>
      case 'title'
        fprintf_title(strfull);
      case 'subtitle'
        fprintf_subtitle(strfull);
      otherwise
        error('input:error','unknown style');
    end
  end
  