function varargout = myom_check_geometry ( headmodel )


% Checks that OpenMEEG is installed and the binaries are valid.
myom_init


% Uses dummy conductivities, if required.
if ~isfield ( headmodel, 'cond' )
    headmodel.cond = ones ( 1, numel ( headmodel.bnd ) );
end


% Generates a temporal name prefix.
tmpprefix = tempname;

% Writes the geometry files.
myom_write_geometry ( tmpprefix, headmodel )

% Checks the triangle files and the geometry file.
% Will find intersections and self-intersections.
% system ( sprintf ( 'om_mesh_info -i "%s_brain.tri"', tmpprefix ) );
% system ( sprintf ( 'om_mesh_info -i "%s_skull.tri"', tmpprefix ) );
% system ( sprintf ( 'om_mesh_info -i "%s_scalp.tri"', tmpprefix ) );
[ status, output ] = system ( sprintf ( 'om_check_geom -g "%s.geom"', tmpprefix ) );

% Deletes the files.
delete ( sprintf ( '%s_*', tmpprefix ) );


% Shows the results, if requested.
if myom_verbosity
    
    % Shows the output of om_check_geom.
    fprintf ( 1, '%s\n', output );
    fprintf ( 1, '\n' );
    
    % Checks that the meshes are closed.
    % A closed mesh has an Euler characteristic of 2.
    fprintf ( 1, 'The Euler characteristic of the first mesh is %i.\n',  mesheuler ( headmodel.bnd (1).tri ) );
    fprintf ( 1, 'The Euler characteristic of the second mesh is %i.\n', mesheuler ( headmodel.bnd (2).tri ) );
    fprintf ( 1, 'The Euler characteristic of the third mesh is %i.\n',  mesheuler ( headmodel.bnd (3).tri ) );
    fprintf ( 1, '\n' );
end


% Prepares the output, if requested.
if nargout > 0
    varargout {1} = status == 0;
end    
