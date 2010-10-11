function data = artefact_rejection_lowmem(directory,stage2directory)
  % data = artefact_rejection(directory)
  %
  % The main function for artefact rejection. Takes as an input the
  % directory containing all the .mat files, after they have been converted
  % from .src files.
  
  % ======================
  % SPIKEMONGER v1.0.0.19
  % ======================
  %   - NCR 04-Jul-2009
  %   - distributed under GPL v3 (see COPYING)
  
  SPIKEMONGER_VERSION = 'v1.0.0.19';
  

%% parameters
% =============

% how many simultaneous spikes are considered questionable
  global THRESHOLD_nss_FOR_CONSIDERATION;
         THRESHOLD_nss_FOR_CONSIDERATION = 5;

% size of the window for simultaneous events (default=0)
  global SIMULTANEOUS_EVENT_WINDOW_SIZE;
         SIMULTANEOUS_EVENT_WINDOW_SIZE = 0;
         
% default excision size (in +/- dt)
  global DEFAULT_ACTION_n;  
         DEFAULT_ACTION_n = SIMULTANEOUS_EVENT_WINDOW_SIZE + 1;  

% default sort mode
  sort_mode = 'by_worst_sweep';   % start with the worst sweep
 %sort_mode = 'by_worst_nss';     % start with the worst single event
  
%% import data
% ================

  % file information
    directory = fixpath(directory);
    files.data = dir([directory '*.mat']);
    n.electrodes = L(files.data);
    electrodes = zeros(1,n.electrodes);

  % import
    fprintf(['  - importing data']);
    data = struct;
    for ii=1:n.electrodes
      dt = load([directory files.data(ii).name]);
		dt.data.spikes = rmfield(dt.data.spikes,{'shapes_aligned','shapes'});
		dt.data = rmfield(dt.data,'sweeps');
		  try
			  dt.data = rmfield(dt.data,'src');
		  catch
		  end		
      fields = fieldnames(dt.data);
      for jj=1:L(fields)
        data(ii).(fields{jj}) = dt.data.(fields{jj});
      end
      electrodes(ii) = data(ii).metadata.electrode;		
		fprintf('.');
	 end
	 clear dt;
    fprintf('\n');
    
  % reorganise based on electrode numbers
    data = data(pick( sortrows([electrodes; 1:n.electrodes]' ),':,2'));
    n.electrodes = L(data);

    
%% sanity check: that they all have the same features
% ==========================================================

% all have the same dt
  if ~( L(unique(reach(data,'metadata.dt'))) == 1 )
    error('sanity:check', 'failed sanity check: dt is not the same for all electrodes');
  end
  
% all have the same maxt_ms
  if ~( L(unique(reach(data,'metadata.maxt_dt'))) == 1 )
    error('sanity:check', 'failed sanity check: maxt_dt is not the same for all electrodes');
  end

% all have the same maxt_dt
  if ~( L(unique(reach(data,'metadata.maxt_ms'))) == 1 )
    error('sanity:check', 'failed sanity check: maxt_ms is not the same for all electrodes');
  end
  
% all have the same n.sweeps
%  if ~( L(unique(Lincell({data.sweeps}))) == 1)
%    error('sanity:check', 'failed sanity check: n.sweeps is not the same for all electrodes');
%  end
      


%% extract spike info
% ======================

  % spike times, in one cell
    allspikes.t_absolute_dt = cell(1,n.electrodes);
    for ii=1:n.electrodes
      allspikes.t_absolute_dt{ii} = data(ii).spikes.t_absolute_dt;
    end

  % how many simultaneous spikes occur concurrently for each one of these
  % (nss)    
    sews = SIMULTANEOUS_EVENT_WINDOW_SIZE;
    nss = allspikes.t_absolute_dt;
    for ii=1:n.electrodes
      nss{ii} = 1 + 0*nss{ii};
      for jj=1:n.electrodes
        if jj==ii
          continue;
        else
          if isempty(allspikes.t_absolute_dt{jj})
            t_jj = [];
          else
            t_jj = ...
              repmat(allspikes.t_absolute_dt{jj},[2*sews+1,1])...
              +repmat([-sews:sews]',[1 length(allspikes.t_absolute_dt{jj})]);
            nss{ii} = nss{ii} + ismember(allspikes.t_absolute_dt{ii}, t_jj);
          end
        end
      end
    end
    allspikes.n_simultaneous_spikes = nss;
    
    a = struct;
      a.t = cell2mat(allspikes.t_absolute_dt);
      a.nspikes = Lincell(allspikes.t_absolute_dt);
      a.electrode = nan(1,sum(a.nspikes));
      a.position  = nan(1,sum(a.nspikes));
        electrode = 1;
        position  = 0;
        for ii=1:L(allspikes.t_absolute_dt)
          a.electrode( position+(1:a.nspikes(ii)) ) = electrode;
          a.position( position+(1:a.nspikes(ii)) )  = 1:a.nspikes(ii);
          position = position + a.nspikes(ii);
          electrode = electrode + 1;
        end        
      a.sorted = sortrows([a.t; a.electrode; a.position]')';
    allspikes.all = a.sorted(1,:);

    
    allspikes.unique = unique(allspikes.all);
    [junk posn] = ismember( allspikes.unique, cell2mat(allspikes.t_absolute_dt) );
    allspikes.nss  = pick( cell2mat(allspikes.n_simultaneous_spikes), posn );
    
%% spike times within a given repeat (for plot 1)
% ================================================

global maxt_dt;
dt        = data(1).metadata.dt;
maxt_dt   = data(1).metadata.maxt_dt;
n.sets    = data(1).metadata.n.sets;
n.repeats = data(1).metadata.n.repeats;

for ii=1:n.electrodes
  allspikes.t_inrepeat_dt{ii} = mod(allspikes.t_absolute_dt{ii}, n.sets * maxt_dt);
  allspikes.whichrepeat{ii}   = 1 + floor(allspikes.t_absolute_dt{ii} / ( n.sets * maxt_dt));
end
   

%% plot
% =========

  fprintf(['  - plotting']);
  figure(1);
  clf;
  set(gcf,'name',data(1).metadata.prefix)

  for sp=1:6
    subplot(3,3,sp);
    hold on;

  % colours
    cols  = hot;
    colf1 = @(x) 2 / (1 + exp(-(x-n.electrodes)/18));
    colf2 = @(x) cols( round(33-x), : )*colf1(x) + [1 1 1]*(1-colf1(x));
    
  % vertical location of a point representing repeat r and electrode e
    yy = @(r,e) (r-1)*(1.25*n.electrodes) + e;

  % lines demarcating individual sweeps
    for ii=1:n.sets
      plot(ii*maxt_dt*[1 1],[0 yy(n.repeats,n.electrodes)],'-','color',0.9*[1 1 1]);
    end
    
  % lines demarcating individual repeats
    for ii=0:n.repeats
      plot([0 maxt_dt*n.sets], 0.5*(yy(ii,n.electrodes)+yy(ii+1,1))*[1 1],'-','color',0.9*[1 1 1]);
    end

  % run through each repeat, then each electrode, then each number of
  % simultaneous spikes

    for ee=1:n.electrodes
      for ss=1:n.electrodes

        % spike times, within the repeat
          tt = allspikes.t_inrepeat_dt{ee};
        % only pick those with ss simultaneous spikes
          tokeep  = allspikes.n_simultaneous_spikes{ee} == ss;
          tt      = tt(tokeep);
        % colour
          col     = colf2(ss);
        % markersize
          msize = 6;
          if sp==1, msize=4.5; end
        % plot
          plot( tt, yy( allspikes.whichrepeat{ee}(tokeep) , ee),...
            '.','color',col,'markersize',msize)

      end
    end

  % aesthetics
    box on;
    xlim([0 n.sets*maxt_dt]);
    ylim([0 yy(n.repeats,n.electrodes)]);
    
    xmax_t  = n.sets * maxt_dt * dt;
    xmax_dt = n.sets * maxt_dt;
    xticks      = ([0 0.25 0.5 0.75 1].*xmax_dt);
    xticklabels = round([0 0.25 0.5 0.75 1].*xmax_t/1000);
        
    yticks = 1:n.repeats;
    if n.repeats > 10
      yticks = floor(1 + (0:0.25:1)*(n.repeats-1));
    elseif n.repeats > 5
      yticks = [1 floor(n.repeats/2) n.repeats];
    end    
    set(gca,'xtick',xticks,'xticklabel',xticklabels);
    set(gca, 'ytick', yy(yticks,n.electrodes/2), 'yticklabel', yticks);
  
    switch sp
      case {1 4}
        ylabel('repeat #','fontsize',14,'fontweight','bold');
    end
    switch sp
      case 1
        title('time (s)','fontsize',14,'fontweight','bold');
      case 2
        title('+/- 1 sweep length','fontsize',12,'fontweight','bold');
      case 3
        title('+/- 400ms','fontsize',12,'fontweight','bold');
        xlabel('dt steps');        
      case 4
        title('+/- 40ms','fontsize',12,'fontweight','bold');
        xlabel('dt steps');
      case 5
        title('+/- 4ms','fontsize',12,'fontweight','bold');
        xlabel('dt steps');
      case 6
        title('+/- 400us','fontsize',12,'fontweight','bold');
        xlabel('dt steps');        
    end

    fprintf('.');  
  end
  fprintf('\n');

%% prepare excisions structures
% ===============================

% which events to look at  
  tolookat = allspikes.nss > THRESHOLD_nss_FOR_CONSIDERATION;
  
% their absolute times (tt) and number of simultaneous spikes (nss)
% sorted by the number of simultaneous spikes
  to_ask.tt     = allspikes.unique( tolookat );
  to_ask.nss    = allspikes.nss( tolookat );
  
% their repeat number (rr), and times within a repeat (tt_inrepeat)
  to_ask.rr       = 1 + floor( to_ask.tt / (n.sets*maxt_dt) );
  to_ask.tt_in_rr = mod( to_ask.tt, n.sets * maxt_dt);
  
% their sweep number, and the sweep's respective time boundaries
  to_ask.sweepnum           = 1 + floor( (to_ask.tt+1) / maxt_dt );
  to_ask.sweep_tt_boundary  = [...
    maxt_dt * (to_ask.sweepnum-1) + 1; ...
    maxt_dt * to_ask.sweepnum];
  
%% sort
  to_ask = sort_to_ask(to_ask,sort_mode);
  

%% structure to hold excised spike times

  to_excise.tt  = [];
  to_excise.boundaries = zeros(0,2);

  
%% run through the events
% =========================

continue_excising = 1;
while continue_excising
  
  % initialise
  % -----------

    % if there are no more events to consider, then finish
      if L(to_ask.tt)==0
        break;
      end

    % current event
      tt      = to_ask.tt(1);
      nss     = to_ask.nss(1);
      rr      = to_ask.rr(1);
      tt_in_rr = to_ask.tt_in_rr(1);
      sweepnum          = to_ask.sweepnum(1);
      sweep_tt_boundary = to_ask.sweep_tt_boundary(:,1);
        
  
    % update plots
      update_plots(to_ask,n,[]);
        
        
  % ask the user how they want to excise
  % -------------------------------------
  
    continue_actionloop = 1;
    while continue_actionloop

    % ask for what to do
      todo = ask_main_question(to_ask,sort_mode,DEFAULT_ACTION_n);

    % follow this decision
      switch todo
        
        %---
        case 'q'
          excision.spikes.tt = [];
          continue_actionloop = 0;
          continue_excising = 0;
          continue;

        %---
        case 'm'
          switch sort_mode
            case 'by_worst_sweep'
              sort_mode = 'by_worst_nss';
            case 'by_worst_nss'
              sort_mode = 'by_worst_sweep';
          end
          to_ask = sort_to_ask(to_ask,sort_mode);
          tt      = to_ask.tt(1);
          nss     = to_ask.nss(1);
          rr      = to_ask.rr(1);
          tt_in_rr = to_ask.tt_in_rr(1);
          sweepnum          = to_ask.sweepnum(1);
          sweep_tt_boundary = to_ask.sweep_tt_boundary(:,1);
          update_plots(to_ask,n,[]);  
          fprintf('\n\n');
          continue;
          
        %---
        case 'k'
          excision.spikes.tt = [];
          fprintf(['\nrestraint! you just earned ' num2str(nss) ' vegeburger points.\n\n']);

        %---
        case 'n'
          fprintf([...
            '  -----------------------------\n' ...
            '    how many dt steps? \n' ...
            '     [0]: cancel \n' ...
            '  -----------------------------\n' ...
            ]);    
          numsteps = demandnumberinput('      ----> ','nonnegative_integer');
            if numsteps==0, continue; end

          excision.boundary.tt  = tt + numsteps*[-1 1];
            for ii=1:2
              excision.boundary.tt(ii) = max( excision.boundary.tt(ii), sweep_tt_boundary(1) );
              excision.boundary.tt(ii) = min( excision.boundary.tt(ii), sweep_tt_boundary(2) );
            end
          to_excise.boundaries  = [to_excise.boundaries; excision.boundary.tt];
          excision.spikes.tt    = allspikes.all( (allspikes.all >= excision.boundary.tt(1)) & (allspikes.all <= excision.boundary.tt(2)) );
          
          fprintf(['\nyou just earned ' num2str(L(excision.spikes.tt)) ' salmon points.\n\n']);
                    
        %---
        case 'd'
          numsteps              = DEFAULT_ACTION_n;
          excision.boundary.tt  = tt + numsteps*[-1 1];
            for ii=1:2
              excision.boundary.tt(ii) = max( excision.boundary.tt(ii), sweep_tt_boundary(1) );
              excision.boundary.tt(ii) = min( excision.boundary.tt(ii), sweep_tt_boundary(2) );
            end
          to_excise.boundaries  = [to_excise.boundaries; excision.boundary.tt];
          excision.spikes.tt    = allspikes.all( (allspikes.all >= excision.boundary.tt(1)) & (allspikes.all <= excision.boundary.tt(2)) );
          
          fprintf(['\nyou just earned ' num2str(L(excision.spikes.tt)) ' salmon points.\n\n']);

        %---          
        case 'D'
          numsteps            = DEFAULT_ACTION_n;          
          min_nss             = ask_for_min_nss(nss);
            if min_nss == 0,    continue; end
          caseslikethis       = find(to_ask.nss >= min_nss);
          excision.spikes.tt  = [];
          for hh=caseslikethis
            excision.boundary.tt  = to_ask.tt(hh) + numsteps*[-1 1];
              for ii=1:2
                excision.boundary.tt(ii) = max( excision.boundary.tt(ii), to_ask.sweep_tt_boundary(1,hh) );
                excision.boundary.tt(ii) = min( excision.boundary.tt(ii), to_ask.sweep_tt_boundary(2,hh) );
              end
            to_excise.boundaries  = [to_excise.boundaries; excision.boundary.tt];
            excision.spikes.tt    = [excision.spikes.tt, ...
                  allspikes.all( (allspikes.all >= excision.boundary.tt(1)) & (allspikes.all <= excision.boundary.tt(2)) )];
          end
          
          fprintf(['\nyou just earned ' num2str(L(excision.spikes.tt)) ' salmon points.\n\n']);
        
        %---
        case 'K'
          excision.spikes.tt = [];
          tokeep = ~(to_ask.sweepnum == sweepnum);
            nss_saved = sum(to_ask.nss(~tokeep));
          tokeep(1) = 1; % ignore the first one, this will be removed below
          to_ask_fields = fieldnames(to_ask);
          for ii=1:L(to_ask_fields)
            field = to_ask_fields{ii};
            to_ask.(field) = to_ask.(field)(:,tokeep);
          end
          fprintf(['\nrestraint! you just earned ' num2str(nss_saved) ' vegeburger points.\n\n']);
          
        %---          
        case 'b'
          fprintf([...
            '  ----------------------------------------\n' ...
            '    click two points to mark x boundary \n' ...
            '        (on any graph) \n' ...
            '  ----------------------------------------\n' ...
            ]);    
          [x y] = ginput(2);
          excision.boundary.tt_in_rr = [floor(min(x)) ceil(max(x))];
          excision.boundary.tt  = excision.boundary.tt_in_rr + (rr-1)*n.sets*maxt_dt;
            for ii=1:2
              excision.boundary.tt(ii) = max( excision.boundary.tt(ii), sweep_tt_boundary(1) );
              excision.boundary.tt(ii) = min( excision.boundary.tt(ii), sweep_tt_boundary(2) );
            end
          excision.boundary.tt  = sort(excision.boundary.tt);

          if diff(excision.boundary.tt) > 0
            to_excise.boundaries  = [to_excise.boundaries; excision.boundary.tt];
            excision.spikes.tt    = allspikes.all( (allspikes.all >= excision.boundary.tt(1)) & (allspikes.all <= excision.boundary.tt(2)) );
            fprintf(['\nyou just earned ' num2str(L(excision.spikes.tt)) ' salmon points.\n\n']);
          else
            excision.spikes.tt = [];
            fprintf(['\nrestraint! you just earned ' num2str(nss) ' vegeburger points.\n\n']);
          end

          
        %---
        case 'S'
          try
            excision.boundary.tt  = [sweep_tt_boundary(1) sweep_tt_boundary(2)];
          catch
            1+1
          end
          to_excise.boundaries  = [to_excise.boundaries; excision.boundary.tt];
          excision.spikes.tt    = allspikes.all( (allspikes.all >= excision.boundary.tt(1)) & (allspikes.all <= excision.boundary.tt(2)) );
          
          fprintf(['\nyou just earned ' num2str(L(excision.spikes.tt)) ' salmon points.\n\n']);

          
          
      end % of following decision
          
      
      continue_actionloop = 0;
    end % of actionloop

    
    % add excisions, and plot them
    % -----------------------------
      to_excise.tt = [to_excise.tt excision.spikes.tt];
      for sp=1:6
        subplot(3,3,sp);
        for ee=1:n.electrodes
            % spike times, within the repeat
              tt_in_rr = allspikes.t_inrepeat_dt{ee} ( ismember(allspikes.t_absolute_dt{ee}, excision.spikes.tt) );
            % which repeat
              rr      = allspikes.whichrepeat{ee} ( ismember(allspikes.t_absolute_dt{ee}, excision.spikes.tt) );
            % colour
              col     = [0 0.8 0.4];
            % markersize
              msize = 6;
              if sp==1, msize=4.5; end
            % plot
              plot( tt_in_rr, yy(rr,ee), '.','color',col,'markersize',msize);
        end
      end

    % remove the excisions from the to_ask list
    % ------------------------------------------
      indices_for_next_cycle = intersect(...
        2:L(to_ask.tt), ...
        find(~ismember(to_ask.tt, to_excise.tt)));
      to_ask.tt       = to_ask.tt(indices_for_next_cycle);
      to_ask.nss      = to_ask.nss(indices_for_next_cycle);
      to_ask.rr       = to_ask.rr(indices_for_next_cycle);
      to_ask.tt_in_rr  = to_ask.tt_in_rr(indices_for_next_cycle);
      to_ask.sweepnum = to_ask.sweepnum(indices_for_next_cycle);
      to_ask.sweep_tt_boundary = to_ask.sweep_tt_boundary(:,indices_for_next_cycle);

      fprintf(['\n' num2str(L(indices_for_next_cycle)) ' remaining questions to ask...\n\n']);

        
end % of excision loop

fprintf(['\nYou earned a total of ' num2str(L(to_excise.tt)) ' salmon points.\n\n']);



%% create excision substructure 
% ==============================

% info
  boundaries = struct;
    boundaries.t_absolute_dt = sortrows( to_excise.boundaries );
    boundaries.t_absolute_ms = boundaries.t_absolute_dt * dt;
      
    boundaries.sweeps         = zeros(size(boundaries.t_absolute_dt));
    boundaries.t_relative_dt  = zeros(size(boundaries.t_absolute_dt));
    for ii=1:size(boundaries.t_absolute_dt, 1)
      for jj=1:size(boundaries.t_absolute_dt, 2)
        [boundaries.sweeps(ii,jj) boundaries.t_relative_dt(ii,jj)] = ...
          locate_absolutetime(boundaries.t_absolute_dt(ii,jj), maxt_dt);
      end
    end
    
    if any(diff(boundaries.sweeps, [], 2))
      error('boundary:error','somehow, we have an excision spread across two sweeps');
    end
    boundaries.sweeps = boundaries.sweeps(:,1);
      
  durations = struct;
    durations.dt = 1 + diff(boundaries.t_absolute_dt,[],2);
    durations.ms = 1 + diff(boundaries.t_absolute_ms,[],2);
    
% remove any duplicates
  excisions = struct;
  excisions.boundaries  = boundaries;
  excisions.durations   = durations;
  excisions = remove_duplicated_excisions(excisions,maxt_dt,dt);
  durations = excisions.durations;
  boundaries = excisions.boundaries;
  
  
%% remove excised spikes from data
% ==================================

% for output
  all_channel_data = rmfield(data,{'set_params','spikes'});

fprintf(['  - re-importing data and removing excised spikes']);

for ii=1:n.electrodes
%%	% re-import
		data = struct;
      datat = load([directory files.data(ii).name]);	
		  try
			  datat.d = rmfield(datat.data,'src');
		  catch
		  end
      fields = fieldnames(datat.data);
      for jj=1:L(fields)
        data(ii).(fields{jj}) = datat.data.(fields{jj});
		end
		clear datat
      electrodes(ii) = data(ii).metadata.electrode;		
		fprintf('.');

%%  % remove from data.spikes
    toremove  = ismember(data(ii).spikes.t_absolute_dt, to_excise.tt);
    if sum(toremove)==0
      continue;
    end
    tokeep    = ~toremove;
       
    sweeps_to_refresh = unique( data(ii).spikes.sweep_id(toremove) );    % note the sweepid for later
    if L(sweeps_to_refresh) == 0
      continue;
    end

    fields = fieldnames(data(ii).spikes);
    for ff=1:L(fields)
      field = fields{ff};
      data(ii).spikes.(field) = data(ii).spikes.(field)(:,tokeep);
    end
    
%% % remove from data.sweeps
    for jj=sweeps_to_refresh
      dst = data(ii).sweeps(jj);       % temp structure
      toremove  = ismember( dst.spike_t_absolute_dt, to_excise.tt );
      tokeep    = ~toremove;
      
      fields = {...
        'spike_t_insweep_ms','spike_t_insweep_dt','spike_t_absolute_ms',...
        'spike_t_absolute_dt','spike_shapes','spike_set_id','spike_repeat_id',...
        'spike_sweep_id','spike_presentation_order' };

      for ff=1:L(fields)
        field = fields{ff};
        dst.(field) = dst.(field)(:,tokeep);
      end
      data(ii).sweeps(jj) = dst;
    end

%% % insert excision metadata
    data(ii).excisions.boundaries = boundaries;
    data(ii).excisions.durations  = durations;
    
    for jj=1:L(boundaries.sweeps)
      sw = boundaries.sweeps(jj);
      try
        exc = data(ii).sweeps(sw).excisions_insweep_dt;
      catch
        exc = [];
      end
      exc = [exc boundaries.t_relative_dt(jj,:)'];
      data(ii).sweeps(sw).excisions.insweep_dt = exc;
      data(ii).sweeps(sw).excisions.insweep_ms = exc * dt;
    end
    
    for sw=unique(boundaries.sweeps)'
      exc = data(ii).sweeps(sw).excisions.insweep_dt;
      data(ii).sweeps(sw).excisions.percent_excised   = 100 * (sum(1+diff(exc)) / maxt_dt);
      data(ii).sweeps(sw).excisions.percent_remaining = 100 - 100 * (sum(1+diff(exc)) / maxt_dt);
	 end
    
% version info
    data(ii).metadata.spikemonger_version = SPIKEMONGER_VERSION;
  
% save
    data = data(ii);
	 save([stage2directory data.metadata.filename],'data','-v6');
  
end
  
%% last bit of cleanup
% =======================

data = all_channel_data;
try
  %close(1);
catch
end
clear global dt maxt_dt ann;
fprintf(['\n  - done.\n']);

end


%% functions
% ============

function to_ask = sort_to_ask(to_ask,sort_mode)
  switch sort_mode
    case 'by_worst_nss'
      allfields  = [to_ask.nss; to_ask.tt; to_ask.rr; to_ask.tt_in_rr; to_ask.sweepnum; to_ask.sweep_tt_boundary];
      allfields  = fliplr(sortrows(allfields')');
      to_ask.nss = allfields(1,:);
      to_ask.tt  = allfields(2,:);
      to_ask.rr  = allfields(3,:);
      to_ask.tt_in_rr = allfields(4,:);
      to_ask.sweepnum = allfields(5,:);
      to_ask.sweep_tt_boundary = allfields(6:7,:);
    case 'by_worst_sweep'
      max_sweepnum  = max(to_ask.sweepnum);
      sweeps.n      = 1:max_sweepnum;
      sweeps.nss = zeros(1,max_sweepnum);
      for ii=1:max_sweepnum
        sweeps.nss(ii) = sum(to_ask.nss(to_ask.sweepnum == ii));
      end
      to_ask.sweep_severity = sweeps.nss(to_ask.sweepnum);
      allfields  = [to_ask.sweep_severity; to_ask.nss; to_ask.tt; to_ask.rr; to_ask.tt_in_rr; to_ask.sweepnum; to_ask.sweep_tt_boundary];
      allfields  = fliplr(sortrows(allfields')');
      to_ask.sweep_severity = allfields(1,:);
      to_ask.nss = allfields(2,:);
      to_ask.tt  = allfields(3,:);
      to_ask.rr  = allfields(4,:);
      to_ask.tt_in_rr = allfields(5,:);
      to_ask.sweepnum = allfields(6,:);
      to_ask.sweep_tt_boundary = allfields(7:8,:);  
    otherwise
      error('sort_mode:unrecognised','sort_mode can only be "by_worst_nss" or "by_worst_sweep"');
  end
end


% ---
function todo = ask_main_question(to_ask,sort_mode,DEFAULT_ACTION_n)
  clc;
  switch sort_mode
    
    case 'by_worst_sweep'
      str.sweep           = num2str(to_ask.sweepnum(1));
      str.spikes_in_sweep = num2str(sum(to_ask.nss(to_ask.sweepnum == to_ask.sweepnum(1))));
      str.spikes_in_event = num2str(to_ask.nss(1));

      str.title = cell(1,3);
      str.title{1} = ['||  SWEEP ' str.sweep '   '];
      str.title{2} = ['||    # concurrent spikes in this sweep = ' str.spikes_in_sweep '   '];
      str.title{3} = ['||    # concurrent spikes in this event = ' str.spikes_in_event '   '];
      str.l = max(Lincell(str.title));
      for ii=1:3
        str.title{ii} = [str.title{ii} repmat(' ',1,str.l-L(str.title{ii})) '||'];
      end
      str.line = repmat('=',1,L(str.title{1}));
      
      fprintf([...
        str.line '\n'...
        str.title{1} '\n'...
        str.line '\n' ...
        str.title{2} '\n'...
        str.title{3} '\n'...
        '========================================================\n' ...
        '  [k]: keep \n' ...
        '  [K]: keep rest of sweep \n'...
        ' \n'...
        '  [n]: delete any spikes (n x dt) before/after event \n' ...
        '  [b]: specify excision boundary \n' ...
        '  [d]: default action for this event   (' num2str(DEFAULT_ACTION_n) ' x dt) \n' ...
        ' \n'...
        '  [S]: excise entire sweep \n'...
        ' \n'...
        '  [m]: switch to event-by-event mode \n'...
        '  [q]: quit, save, and forget the rest \n' ...
        '========================================================\n' ...
        ]);    
      todo = demandinput('      ----> ',{'k','n','b','d','K','S','q','m'});

      
    case 'by_worst_nss'
      titlestr1 = ['||   # CONCURRENT SPIKES = ' num2str(to_ask.nss(1)) '   ||'];
      titlestr0 = repmat('=',1,L(titlestr1));
      fprintf([...
        titlestr0 '\n'...
        titlestr1 '\n'...
        '========================================================\n' ...
        '  [k]: keep \n' ...
        '  [n]: delete any spikes (n x dt) before/after event \n' ...
        '  [b]: specify excision boundary \n' ...
        ' \n'...
        '  [d]: default action for this event   (' num2str(DEFAULT_ACTION_n) ' x dt) \n' ...
        '  [D]: default action for all events (set lower threshold) \n' ...
        ' \n'...
        '  [S]: excise entire sweep \n'...
        ' \n'...
        '  [m]: switch to sweep-by-sweep mode \n'...
        '  [q]: quit, save, and forget the rest \n' ...
        '========================================================\n' ...
        ]);    
      todo = demandinput('      ----> ',{'k','n','b','d','D','S','q','m'});
  end
end


% ---
function update_plots(to_ask,n,shapes)
  global ann DEFAULT_ACTION_n maxt_dt;

  % current event
    tt      = to_ask.tt(1);
    nss     = to_ask.nss(1);
    rr      = to_ask.rr(1);
    tt_in_rr = to_ask.tt_in_rr(1);
    sweepnum          = to_ask.sweepnum(1);
    sweep_tt_boundary = to_ask.sweep_tt_boundary(:,1);

  % boundaries of zoom-plots
    yy = @(r,e) (r-1)*(1.25*n.electrodes) + e;
    ymin.small = yy(rr,1) - 2;
    ymax.small = yy(rr,n.electrodes) + 2;
    ymin.big = yy(rr-1,1);
    ymax.big = yy(rr+1,n.electrodes);

  % zoom in to zoom-plots!
    subplot(3,3,2);
      xlim(tt_in_rr + maxt_dt*1.1*[-1 1]);
      ylim([ymin.big ymax.big]);

    subplot(3,3,3);
      xlim(tt_in_rr + [-1.0.0.190000]);
      ylim([ymin.small ymax.small]);
      set(gca,'xtick', tt_in_rr+[-10000:2000:10000], 'xticklabel', {'','-8000','','-4000','','0','','4000','','8000',''});

    subplot(3,3,4);
      xlim(tt_in_rr + [-1000 1000]);
      ylim([ymin.small ymax.small]);
      set(gca,'xtick', tt_in_rr+[-1000:200:1000], 'xticklabel', {'','-800','','-400','','0','','400','','800',''});

    subplot(3,3,5);
      xlim(tt_in_rr + [-100 100]);
      ylim([ymin.small ymax.small]);
      set(gca,'xtick', tt_in_rr+[-100:20:100], 'xticklabel', {'','-80','','-40','','0','','40','','80',''});

    subplot(3,3,6);
      xlim(tt_in_rr + [-10 10]);
      ylim([ymin.small ymax.small]);
      set(gca,'xtick', tt_in_rr+[-10:2:10], 'xticklabel', {'','-8','','-4','','0','','4','','8',''});

  % add a default line bar to most-zoomed-in plot
    subplot(3,3,6);
    plot(tt_in_rr + -DEFAULT_ACTION_n*[1 1]-0.5, ylim, '--','color',[0.5 0.5 1]);
    plot(tt_in_rr +  DEFAULT_ACTION_n*[1 1]+0.5, ylim, '--','color',[0.5 0.5 1]);


  % add an annotation box to wide scale view
    try
      delete(ann.obj);
    catch
    end
    subplot(3,3,1);
      [ann.pos.xmin ann.pos.ymin] = dsxy2figxy(gca, tt_in_rr - 1.5*maxt_dt, ymin.small);
      [ann.pos.xmax ann.pos.ymax] = dsxy2figxy(gca, tt_in_rr + 1.5*maxt_dt, ymax.small);
      ann.pos.xsize = ann.pos.xmax - ann.pos.xmin;
      ann.pos.ysize = ann.pos.ymax - ann.pos.ymin;
      try
      ann.obj = annotation(...
        'rectangle', [ann.pos.xmin ann.pos.ymin ann.pos.xsize ann.pos.ysize],...
        'color',[0 0 1], ...
        'linewidth',2);
      catch
      end
      %drawnow;

%   % plot spike shapes
%     subplot(3,2,5);
%       hold off;
%       plot(shapes,'color',[0.2 0 0]);
%     xlim([1 27]);
%     ylim([-127 127]);
%     set(gca,'xtick',0:9:27,'xticklabel',{},'ytick',[-127 -63 0 63 127],'yticklabel',{});
%       xlabel('spike shapes','fontsize',14,'fontweight','bold');

%   % plot spike shape cross-correlogram
%     subplot(3,2,6);
%       hold off;
%       imagesc(corrcoef(shapes))
%       caxis([0 1]);
%     set(gca,'xtick',0:9:27,'xticklabel',{},'ytick',0:9:27,'yticklabel',{});
%       xlabel('shape xcorr','fontsize',14,'fontweight','bold');
end


function min_nss = ask_for_min_nss(nss)
  global THRESHOLD_nss_FOR_CONSIDERATION;
  tnssfc = THRESHOLD_nss_FOR_CONSIDERATION;
  fprintf([...
    '  ---------------------------------------------------------\n' ...
    '    there are ' num2str(nss) ' concurrent events here. \n' ...
    ' \n'...
    '    to what minimum number of concurrent events \n'...
    '    do you wish to apply the default action? \n'...
    '           [' num2str(max(tnssfc,1)) '-' num2str(nss) '] \n'...
    '           [0]: cancel \n' ...
    '  ---------------------------------------------------------\n' ...
    ]);    
  min_nss = demandnumberinput('      ----> ',[0 max(tnssfc,1):nss]);
end
    