function headmodel = myom_check_headmodel ( headmodel )


% Gets the number of meshes.
nmeshes = numel ( headmodel.bnd );

% Sorts the meshes from inner to outer.
order = ordermesh ( headmodel.bnd );

if isfield ( headmodel, 'bnd' ),    headmodel.bnd    = headmodel.bnd    ( order ); end
if isfield ( headmodel, 'tissue' ), headmodel.tissue = headmodel.tissue ( order ); end
if isfield ( headmodel, 'cond' ),   headmodel.cond   = headmodel.cond   ( order ); end


% Initializes the tissue labels, if needed.
if ~isfield ( headmodel, 'tissue' )
    headmodel.tissue = cellfun ( @(x) sprintf ( 'Tissue %i', x ), num2cell ( 1: nmeshes ), 'UniformOutput', false );
end

% Initializes the conductivities, if needed.
if ~isfield ( headmodel, 'cond' )
    warning ( 'No conductivity is declared. Assuming standard values.\n' )
    
    if nmeshes == 1
        headmodel.cond = 1;
    elseif nmeshes == 3
        headmodel.cond = [ 1 1/80 1 ] / 3;
    else
        error ( 'Conductivity values are required for 2 shells. More than 3 shells not allowed.' )
    end
end

% Marks the skin surfaces and the source bounding surface.
headmodel.type = 'openmeeg';
headmodel.source = 1;
headmodel.skin_surface = nmeshes;


% Checks the orientation of each surface.
for mindex = 1: nmeshes
    
    % For OpenMEEG the normals of the meshes mush be inward-oriented.
    if ~checkomnormals ( headmodel.bnd ( mindex ) )
        
        if myom_verbosity, fprintf ( 1, 'Flipping the normals in mesh %i to fit OpenMEEG convention.\n', mindex ); end
        
        % Flips the triangle definition.
        headmodel.bnd ( mindex ).tri = fliplr ( headmodel.bnd ( mindex ).tri );
    end
    
    % Calculates the normal of each point.
    headmodel.bnd ( mindex ).nrm = ft_normals ( headmodel.bnd ( mindex ).pos, headmodel.bnd ( mindex ).tri );
end


% Last, checks the version of OpenMEEG, if installed.
[ status, output ] = system ( 'om_assemble' );

% Compares the version of OpenMEEG with the version of the headmodel.
if ~status
    
    % Extracts the binary versions.
    hits = regexp ( output, 'version (\d\.\d\.\d)', 'tokens' );
    version = hits {1} {1};
    
    % Sets the version of the head model if no defined.
    if ~isfield ( headmodel, 'version' )
        headmodel.version = version;
    end
    
    % Compares it to the version previously used.
    if ~strcmp ( headmodel.version, version )
        error ( 'The provided headmodel was generated with a different version of OpenMEEG.' )
    end
end


function correct = checkomnormals ( bnd )

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


function order = ordermesh ( bnd )
% Orders the meshes from inner to outter.

% Based on FieldTrip functions:
% * surface_nesting
% * bounding_mesh by Robert Oostenveld
% * solid_angle by Robert Oostenveld


% Defines the variables.
npnt    = 10;
maxiter = 5;

% Gets the metadata.
nbnd    = numel ( bnd );
nesting = zeros ( nbnd );

% Compares each pair of meshes.
for i = 1: nbnd
    for j = 1: nbnd
        
        % If the meshes are the same continues.
        if i == j, continue, end
            
        % Initializes the solid angle.
        sangs = 0;
        
        % Takes several random points of the mesh i.
        for pindex = 1: npnt
            
            % Gets a random point of the mesh i.
            pnt = randi ( size ( bnd ( i ).pos, 1 ) );
            pnt = bnd ( i ).pos ( pnt, : );
            
            % Centers the mesh j in the selected point.
            tmp = bnd ( j ).pos - pnt;
            
            % Calculates the solid angle of the mesh j.
            sang  = sum ( my_solang ( tmp, bnd ( j ).tri ), 'omitnan' );
            sangs = sangs + abs ( sang );
        end
        
        nesting ( i, j ) = round ( sangs / ( npnt * 4 * pi ) );
    end
end

% Gets the order of the meshes.
[ ~, order ] = sort ( -sum ( nesting, 2 ) );

% Checks for ambiguities.
if any ( any ( nesting & nesting' ) )
    
    % Gets the number of iterations.
    stack = dbstack;
    if sum ( strcmp ( { stack.name } , stack ( end ).name ) ) > maxiter
        error ( 'Order not found after %i tries.\n', maxiter )
    end
    
    % Repeats the process iteratively.
    order = ordermesh ( bnd );
end
