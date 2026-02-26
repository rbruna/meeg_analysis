function bnd = NFT_mfc ( bnd )
% mesh_final_correction()
% Performs mesh correction for scalp, skull, csf and brain.

% Based on NFT 2.3 functions:
% * mesh_final_correction by Zeynep Akalin Acar


% Orders the meshes from inner to outter.
order = ordermesh ( bnd );
bnd   = bnd ( order );

% Checks that no mesh intersects with the outter one.
for mindex = 1: numel ( bnd ) - 1
    
    % Gets the meshes to compare.
    imesh = bnd ( mindex );
    omesh = bnd ( mindex + 1 );
    
    % Checks if any point of the inside mesh is outside the outter mesh.
    bnd ( mindex ).pos = NFT_mci ( imesh.pos, omesh.pos, omesh.tri );
end

% Restores the original mesh order.
bnd ( order ) = bnd;



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
            pos = randi ( size ( bnd ( i ).pos, 1 ) );
            pos = bnd ( i ).pos ( pos, : );
            
            % Centers the mesh j in the selected point.
            tmp = bsxfun ( @minus, bnd ( j ).pos, pos );
            
            % Calculates the solid angle of the mesh j.
            sang  = nansum ( solid_angle ( tmp, bnd ( j ).tri ) );
            sangs = sangs + abs ( sang );
        end
        
        nesting ( i, j ) = round ( sangs / ( npnt * 4 * pi ) );
    end
end

% Gets the order of the meshes.
[ ~, order ] = sort ( -sum ( nesting, 2 ) );

% Checks form ambiguities.
if any ( any ( nesting & nesting' ) )
    
    % Gets the number of iterations.
    stack = dbstack;
    if sum ( strcmp ( { stack.name } , stack ( end ).name ) ) > maxiter
        error ( 'Order not found after %i tries.\n', maxiter )
    end
    
    % Repeats the process iteratively.
    order = NFT_mfc ( bnd );
end
