function excisions = remove_duplicated_excisions(excisions,maxt_dt,dt)
  % excisions = remove_duplicated_excisions(excisions,maxt_dt,dt)
  %
  % If there are any overlapping excisions, this function concatenates
  % them. 
  %
  % Note that it only preserves the fields:
  %   boundaries.sweeps
  %   boundaries.t_relative_dt
  %   durations.dt
  %   durations.ms
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)


  bd.old = [excisions.boundaries.sweeps excisions.boundaries.t_relative_dt];
  bd.old = sortrows(bd.old);
  
  bd.new = zeros(0,3);

  for ii=unique(bd.old(:,1))'
    
    excs = bd.old((bd.old(:,1)==ii),2:3);
    if size(excs,1)==1
      bd.new = [bd.new; ii excs];
      continue;
    end

    if issorted(pick(sortrows(excs)',':'))
      if all(diff(pick(sortrows(excs)',':')) > 1)
        bd.new = [bd.new; ones(size(excs,1),1) excs];
        continue;
      end
    end
    
    if ismember([1 maxt_dt],excs,'rows')
      bd.new = [bd.new; ii 1 maxt_dt];
      continue;
    end
    
    xx = 0:(maxt_dt+1);
    for jj=1:size(excs,1)
      xx = xx( ~( xx >= excs(jj,1) & xx <= excs(jj,2) ) );
    end    

    if isempty(xx)
      bd.new = [bd.new; ii 1 maxt_dt];
    
    else
      jumplocs = find(~(diff(xx) == 1));
      excs = [...
        xx(jumplocs)+1; ...
        xx(jumplocs+1)-1 ]';
      bd.new = [bd.new; ii*ones(size(excs,1),1) excs];
    end    
    
  end
  
  excisions.boundaries = struct;
  excisions.boundaries.sweeps = bd.new(:,1);
  excisions.boundaries.t_relative_dt = bd.new(:,2:3);
  
  excisions.durations = struct;
  excisions.durations.dt = diff(excisions.boundaries.t_relative_dt,[],2)+1;
  excisions.durations.ms = excisions.durations.dt * dt;
  
end