function bnd = NFT_read_smf ( smfname )

% Iinitializes the output.
bnd = struct ( 'pnt', [], 'tri', [] );

% Opens the file to read.
fid = fopen ( smfname, 'r' );

% Reads the vertices and the triangles.
bnd.pnt = fscanf ( fid, 'v %f %f %f\n', [ 3 inf ] )';
bnd.tri = fscanf ( fid, 't %i %i %i\n', [ 3 inf ] )';
fclose ( fid );

fid = fopen ( 'tal.smf', 'w' );
fprintf ( fid, 'v %f %f %f\n', bnd.pnt' );
fprintf ( fid, 't %i %i %i\n', bnd.tri' );
fclose ( fid );