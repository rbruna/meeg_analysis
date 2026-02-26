function tdpot = myom_srctdpot ( dippos, tpos, gint, pH, vH )

% Sets the default level of Gaussian integration.
if nargin < 3
    gint   = 4;
end

% Gets the normalized Gaussian integration points.
[ gposn, gwein ] = myom_gaussian_tri ( gint );
nint   = numel ( gwein );


% Gets the dimensions of the data.
ntri   = size ( tpos, 2 );
ndip   = size ( dippos, 1 );

% Calculates the integration points for each element.
gpos   = gposn * tpos ( :, : );
gpos   = reshape ( gpos, nint * ntri, 3 );

% Generates a matrix to translate integration points to triangles.
tindex = repmat ( 1: ntri, nint, 1 );
pindex = 1: ntri * nint;
g2t    = sparse ( tindex, pindex, repmat ( gwein, 1, ntri ) );


% Extracts the position of the 1st, 2nd and 3rd nodes of each triangle.
p0     = permute ( tpos ( 1, :, : ), [ 2 3 1 ] );
p1     = permute ( tpos ( 2, :, : ), [ 2 3 1 ] );
p2     = permute ( tpos ( 3, :, : ), [ 2 3 1 ] );

% Calculates the area of each element.
tnor   = cross ( p1 - p0, p2 - p0, 2 );
tnor   = squeeze ( tnor );
tarea  = sqrt ( sum ( tnor .* tnor, 2 ) ) / 2;
tnor   = tnor ./ ( 2 * tarea );

% Extends the normals to match the integration points.
gnor   = reshape ( tnor, 1, ntri, 3 );
gnor   = repmat  ( gnor, nint, 1, 1 );
gnor   = reshape ( gnor, nint * ntri, 3 );


% Calculates the triangle information, if required.
if nargin < 4
    [ pH, vH ] = myom_trih ( p0, p1, p2 );
end

% Extends the heights to match the integration points.
pH     = permute ( pH, [ 4 1 2 3 ] );
pH     = repmat ( pH, nint, 1, 1, 1 );
pH     = reshape ( pH, nint * ntri, 3, 3 );

vH     = permute ( vH, [ 4 1 2 3 ] );
vH     = repmat ( vH, nint, 1, 1, 1 );
vH     = reshape ( vH, nint * ntri, 3, 3 );


% Calculates the gradient of the potential at each dipole.
dpot   = mycd_dpotential ( dippos, gpos, gnor );


% Calculates the influence of each integration point in each node.
P1p    = sum ( vH ( :, :, 1 ) .* ( gpos - pH ( :, :, 1 ) ), 2 );
P2p    = sum ( vH ( :, :, 2 ) .* ( gpos - pH ( :, :, 2 ) ), 2 );
P3p    = sum ( vH ( :, :, 3 ) .* ( gpos - pH ( :, :, 3 ) ), 2 );

% Calculates the gradient of the potential for each integration point.
gdpot1 = -dpot .* P1p;
gdpot2 = -dpot .* P2p;
gdpot3 = -dpot .* P3p;

% Combines all the integration points.
tdpot  = zeros ( ntri, 3 * ndip, 3 );
tdpot ( :, :, 1 ) = g2t * gdpot1;
tdpot ( :, :, 2 ) = g2t * gdpot2;
tdpot ( :, :, 3 ) = g2t * gdpot3;


% Multiplies the results by twice the area of the element.
tdpot  = tdpot .* 2 .* tarea;
