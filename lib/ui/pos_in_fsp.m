function pos = pos_in_fsp2(sh_mean)

n.c = L(sh_mean);
energy = cell2mat(map_to_cell(@var, sh_mean)')';

% get weighted
pos = nan(1,n.c);
pos(1) = -Inf;
for ii=2:n.c
  pos(ii) = get_zcentre_using_moments(energy(:,ii));
end