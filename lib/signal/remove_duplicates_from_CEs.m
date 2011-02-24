function CEs = remove_duplicates_from_CEs(CEs, params)

  which_kept = params.which_kept;
  CEs.time_smp = CEs.time_smp(which_kept);
  CEs.time_ms  = CEs.time_ms(which_kept);
  CEs.time_absolute_s = CEs.time_absolute_s(which_kept,:);
  CEs.trigger  = CEs.trigger(which_kept);
  CEs.shape    = CEs.shape(which_kept,:,:);
  CEs.timestamps = CEs.timestamps(which_kept);
  CEs.fsp_params = params;