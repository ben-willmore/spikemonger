function [tt sh] = get_shape_plot_data(shapes)
  shapes1 = shapes;
  shapes2 = flipud(shapes);
  shape_length = size(shapes,1);
  
  n.spikes = size(shapes,2);
  switch mod(n.spikes,2)
    case 0
      tokeep  = repmat(([true false]),shape_length,n.spikes/2);
      tt      = repmat( ([1:shape_length shape_length:-1:1])',n.spikes/2, 1 );
    case 1
      tokeep = [repmat(([true false]),shape_length,floor(n.spikes/2)) true(shape_length,1)];
      tt = [ repmat( ([1:shape_length shape_length:-1:1])', floor(n.spikes/2), 1 ); (1:shape_length)' ];
  end
  
  shapes1 = shapes1 .* tokeep;
  shapes2 = shapes2 .* (~tokeep);
  sh = shapes1 + shapes2;
  sh = sh(:);
end