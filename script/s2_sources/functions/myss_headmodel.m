function headmodel = myss_headmodel ( headmodel, sens, refsens, extrasens, weights )

% Based on FiedTrip functions:
% * meg_ini by Guido Nolte


% Gets the surface normals, if needed.
if ~isfield ( headmodel.bnd, 'nrm' )
    headmodel.bnd.nrm = normals ( headmodel.bnd.pos, headmodel.bnd.tri );
end

% Marks the head model type.
headmodel.type = 'singleshell';

% Sets the units, if needed.
if ~isfield ( headmodel, 'unit' ) && isfield ( headmodel.bnd, 'unit' )
    headmodel.unit = headmodel.bnd (1).unit;
end

% If no sensors reference exits.
if nargin < 2
    return
end


% Calculates the center of the sphere fitting the mesh.
surf    = headmodel.bnd;
center  = my_fitsphere ( surf.pos );

% Sets the order of the expansion.
order   = 10;

% Composes the sensors and surface matrices.
sensors = cat ( 2, sens.coilpos, sens.coilori );
surface = cat ( 2, surf.pos, surf.nrm );

% Data must be double precission to avoid numeric inestabilities.
sensors = double ( sensors );
surface = double ( surface );

% Stores the parameters.
params         = [];
params.order   = order;
params.center  = center;
params.sensors = sensors;

% Calculates the correction coefficients.
params.coeff_sens = getcoeffs ( sensors, surface, center, order );

if nargin > 2
    params.coeff_ref = getcoeffs ( refsens, surface, center, order );
end

if nargin > 3
    params.coeff_weights = getcoeffs ( extrasens, surface, center, order );
    params.weights = weights;
end

headmodel.params = params;


function coeffs = getcoeffs ( sens, surf, center, order )

% Disables the warnings.
warning ( 'OFF', 'MATLAB:nearlySingularMatrix' );

% Sets the center of the surface as origin.
coilpos = bsxfun ( @minus, sens ( :, 1: 3 ), center );
coilori = sens ( :, 4: 6 );
surfpos = bsxfun ( @minus, surf ( :, 1: 3 ), center );
surfori = surf ( :, 4: 6 );

bt = myss_aux_leadsphere_chans ( surfpos', coilpos', coilori' );
b  = squeeze ( dot3d ( surfori', bt ) );

scale = 10;
[ ~, gradbas ] = myss_aux_legs ( surfpos, surfori, order, scale );
coeffs = ( gradbas' * gradbas ) \ gradbas' * b;

warning ( 'ON', 'MATLAB:nearlySingularMatrix' );


function nrm = normals ( pnt, tri, opt )

% Based on FiedTrip functions:
% * normals by Robert Oostenveld

if nargin < 3
    opt = 'vertex';
elseif strcmpi ( opt (1), 'v' )
    opt = 'vertex';
elseif strcmpi ( opt (1), 't' )
    opt = 'triangle';
else
    error ( 'Invalid optional argument.' );
end

npnt = size ( pnt, 1 );
ntri = size ( tri, 1 );

% Sets the origin as the centroid of the points.
pnt = bsxfun ( @minus, pnt, mean ( pnt, 1 ) );

% Calculates the normals for the triangles.
v2 = pnt ( tri ( :, 2 ), : ) - pnt ( tri ( :, 1 ), : );
v3 = pnt ( tri ( :, 3 ), : ) - pnt ( tri ( :, 1 ), : );
nrm_tri = cross3d ( v2', v3' )';

if strcmp ( opt, 'vertex' )
    
    % Calculates the vertex normal as the average of all its triangles.
    nrm = zeros ( npnt, 3 );
    for i = 1: ntri
        nrm ( tri ( i, 1 ), : ) = nrm ( tri ( i, 1 ), : ) + nrm_tri ( i, : );
        nrm ( tri ( i, 2 ), : ) = nrm ( tri ( i, 2 ), : ) + nrm_tri ( i, : );
        nrm ( tri ( i, 3 ), : ) = nrm ( tri ( i, 3 ), : ) + nrm_tri ( i, : );
    end
else
    nrm = nrm_tri;
end

% Normalizes the normals.
nrm = bsxfun ( @rdivide, nrm, sqrt ( sum ( nrm .^ 2, 2 ) ) );


function cross = cross3d ( vector1, vector2 )

X1 = bsxfun ( @times, circshift ( vector1, -1 ), circshift ( vector2,  1 ) );
X2 = bsxfun ( @times, circshift ( vector1,  1 ), circshift ( vector2, -1 ) );

cross = X1 - X2;


function dot = dot3d ( vector1, vector2 )

dot = sum ( bsxfun ( @times, vector1, vector2 ) );