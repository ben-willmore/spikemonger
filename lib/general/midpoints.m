function xc = midpoints(edges)
  % xc = midpoints(edges)
  xc = (droptail(edges) + drophead(edges))/2;
end