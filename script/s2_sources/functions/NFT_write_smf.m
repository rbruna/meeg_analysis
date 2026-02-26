function bnd = NFT_write_smf ( smfname, bnd )

% Opens the file to write.
fid = fopen ( smfname, 'w' );

% Writes the vertices and the triangles.
fprintf ( fid, 'v %f %f %f\n', bnd.pnt' );
fprintf ( fid, 't %i %i %i\n', bnd.tri' );
fclose ( fid );