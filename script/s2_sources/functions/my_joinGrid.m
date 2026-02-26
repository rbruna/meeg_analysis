function grid = my_joinGrid ( grid1, grid2 )

grid           = grid1;
grid.label     = cat ( 1, grid1.label, grid2.label );
grid.leadfield = cellfun ( @(x,y) cat ( 1, x, y ), grid1.leadfield, grid2.leadfield, 'UniformOutput', false );
