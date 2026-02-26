function NFT_write_asc ( ascname, bnd )

% Recovers the original points coordinates.
tri = bnd.pnt ( bnd.tri (:), : );

% Opens the file to write.
fid = fopen ( ascname, 'w' );

% Prints the triangles vertex in groups of three.
fprintf ( fid, '3\n%f %f %f\n%f %f %f\n%f %f %f\n', tri );
fclose ( fid );

