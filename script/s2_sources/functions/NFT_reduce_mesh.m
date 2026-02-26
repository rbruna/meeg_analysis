function [ bnd, log ] = NFT_reduce_mesh ( bnd, target )

% Based on NFT 2.3 functions:
% * nft_mesh_generation


% Initializes the log.
log = sprintf ( 'Session started %s.\n\n', datestr ( now ) );

% Defines the file names and the options for 'procmesh'.
outfile   = sprintf ( '%s.smf', tempname );
infile    = sprintf ( '%s.smf', tempname );
procmesh1 = NFT_coarse ( outfile );
procmesh2 = NFT_affine ( outfile );

% Gets the original number of polygons.
polygons = numel ( bnd.tri );

% Saves the mesh in a file.
NFT_write_smf ( infile, bnd );

% Reduces the number of polygons iteratively.
while true
    
    % Reduces the number of polygons by a maximum of 1.5.
    polygons = max ( target, round ( polygons / 1.5 ) );
    
    fprintf ( 1, 'Reducing the geometry to %i polygons (the target is %i).\n', polygons, target );
    
    % Coarses the mesh and reduces the number of polygons.
    [ ~, log1 ] = system ( sprintf ( '"./NFT-2.3/bin/procmesh.64" -c "%s" "%s"', procmesh1, infile ) );
    [ ~, log2 ] = system ( sprintf ( '"./NFT-2.3/bin/qslim.64" -c 0.5 -m 5 -o "%s" -t %i "%s"', infile, polygons, outfile ) );
    log = cat ( 2, log, log1, log2 );
    
    % If the target number of polygons is achieved, exits.
    if polygons == target, break, end
end

% Applies the final improvement.
[ ~, log3 ] = system ( sprintf ( '"./NFT-2.3/bin/procmesh.64" -c "%s" "%s"', procmesh2, infile ) );
log = cat ( 2, log, log3 );

% Loads the mesh from the final file.
bnd = NFT_read_smf ( outfile );



function txtname = NFT_coarse ( outname )

% Generates a temporal file.
txtname = sprintf ( '%s.txt', tempname );

% Writes the options in the file.
fid = fopen ( txtname, 'w' );

fprintf ( fid, 'correct 5\n' );
fprintf ( fid, 'smooth 1\n' );
fprintf ( fid, 'correct 5\n' );
fprintf ( fid, 'improve 2 0.1 0.05\n' );
fprintf ( fid, 'improve 2 0.3 0.2\n' );
fprintf ( fid, 'correct 5\n' );
fprintf ( fid, 'prune all\n' );
fprintf ( fid, 'save %s\n', outname );
fprintf ( fid, 'quit\n' );
fclose ( fid );


function txtname = NFT_affine ( outname )

% Generates a temporal file.
txtname = sprintf ( '%s.txt', tempname );

% Writes the options in the file.
fid = fopen ( txtname, 'w' );

fprintf ( fid, 'correct 2\n' );
fprintf ( fid, 'split intersect\n' );
fprintf ( fid, 'fill holes\n' );
fprintf ( fid, 'correct 5\n' );
fprintf ( fid, 'improve 2 0.1 0.05\n' );
fprintf ( fid, 'improve 2 0.3 0.2\n' );
fprintf ( fid, 'correct 5\n' );
fprintf ( fid, 'split intersect\n' );
fprintf ( fid, 'correct 2\n' );
fprintf ( fid, 'prune all\n' );
fprintf ( fid, 'split intersect\n' );
fprintf ( fid, 'fill holes\n' );
fprintf ( fid, 'correct 2\n' );
fprintf ( fid, 'prune all\n' );
fprintf ( fid, 'improve 2 0.1 0.05\n' );
fprintf ( fid, 'correct 2\n' );
fprintf ( fid, 'save %s\n', outname );
fprintf ( fid, 'quit\n' );
fclose ( fid );
