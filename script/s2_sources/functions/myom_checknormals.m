function correct = myom_checknormals ( bnd )

% Gets the vertex and triangles definition.
pnt = bnd.pos;
tri = bnd.tri;

% Centers the mesh in the origin.
pnt = pnt - mean ( pnt );

% Gets the solid angle of the mesh.
sa  = sum ( my_solang ( pnt, tri ) );

% If the solid angle differs from 4pi the mesh is irregular or not closed.
if ( abs ( sa ) - 4 * pi ) > 1000 * eps
    error ( 'The mesh is irregular or not closed.' );
end

% If the solid angle is possitive the normals are correct.
if sa > 0
    correct = true;
else
    correct = false;
end
