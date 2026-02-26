function bnd = NFT_read_asc ( ascname )

% Iinitializes the output.
bnd = struct ( 'pnt', [], 'tri', [] );

% Opens the file to read.
fid = fopen ( ascname, 'r' );

% Reads all the information in the file.
file = fscanf ( fid, '%f', [ 1 + 3 + 3 + 3, inf ] );
fclose ( fid );

% Checks that all the polygons are triangles.
if ~all ( file ( 1, : ) == 3 ), error ( 'Not a triangle.\n' ), end

% Lists the vertices.
pnt = reshape ( file ( 2: end, : ), 3, [] );
pnt = permute ( pnt, [ 2 1 ] );
pnt = unique  ( pnt, 'rows' );

% List the triangles.
tri = reshape ( file ( 2: end, : ), 3, [] );
tri = permute ( tri, [ 2 1 ] );

% Rewrites the triangles with the vertex index.
[ ~, tri ] = ismember ( tri ( :, : ), pnt, 'rows' );
tri = reshape ( tri, 3, [] )';

bnd.pnt = pnt;
bnd.tri = tri;
