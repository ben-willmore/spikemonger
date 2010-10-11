function h = histc_nolast(x,edges)
  h = histc(x,edges);
  h(end-1) = h(end-1)+h(end);
  h = h(1:(end-1));
end