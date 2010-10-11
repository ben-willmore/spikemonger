function create_MW_2(dirs)

%% create MW2

fprintf_bullet('creating aggregation type 2\n',2);

% load core data
t1 = clock;
fprintf_bullet('loading core data...',3);
CEs_all = get_event_file(dirs,'CEs_MW_main');
s = get_event_file(dirs,'CEs_MW_shape_size');
fprintf_timediff(t1);

%  metadata
max_n_events = 5e5;
n = struct;
n.events = L(CEs_all.time_smp);
n.blocks = ceil(n.events/max_n_events);

%%

for blocknum=1:n.blocks
  fprintf_bullet(['block ' n2s(blocknum) '/' n2s(n.blocks)],3);
  t2 = clock;
  
  % event indices in this block
  if blocknum<n.blocks
    n.this = max_n_events;
  else
    n.this = n.events - max_n_events*(blocknum-1);
  end
  idx.this = (blocknum-1)*max_n_events + (1:n.this);
  
  % create CEs for this block
  CEs = CEs_all;
  fields = fieldnames(CEs);
  for ff=1:L(fields)
    fi = fields{ff};
    CEs.(fi) = CEs.(fi)(idx.this);
  end
  
  % insert shapes
  CEs.shape = nan(n.this, s(2), s(3),'single');
  for bb=1:s(3)
    fprintf('.');
    st = get_event_file(dirs,['CEs_MW_sh' n2s(bb,2)]);
    st = st(idx.this, : ,:);
    CEs.shape(:,:,bb) = st;
  end
  
  fprintf('x');
  save_event_file(dirs,CEs,['CEs_MW_all_' n2s(blocknum,2)]);
  fprintf_timediff(t2);
end

end