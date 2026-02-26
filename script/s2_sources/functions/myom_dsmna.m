function srcmat = myom_dsmna ( headmodel, grid, gint )

% Based on OpenMEEG functions:
% * assemble_DipSourceMat by Alexandre Gramfort
% * operatorDipolePot by Alexandre Gramfort
% * operatorDipolePotDer by Alexandre Gramfort


% Sets the default level of Gaussian integration.
if nargin < 3
    gint   = 4;
end

% Gets the normalized Gaussian integration points.
[ gposn, gwein ] = myom_gaussian_tri ( gint );
nint   = numel ( gwein );


% Sanitizes the grid.
grid   = my_fixgrid ( grid );

% Gets the mesh information.
mesh   = headmodel.bnd (1);
cond   = headmodel.cond (1);

% Extracts the dipole positions.
dippos = grid.pos ( grid.inside, : );


% Gets the dimensions of the data.
ntri   = size ( mesh.tri, 1 );
npos   = size ( mesh.pos, 1 );
ndip   = size ( dippos, 1 );


% Extracts the vertices for each triangle.
tpos   = mesh.pos ( mesh.tri', : );
tpos   = reshape ( tpos, 3, ntri, 3 );

% Extracts the position of the 1st, 2nd and 3rd nodes of each triangle.
p0     = squeeze ( tpos ( 1, :, : ) );
p1     = squeeze ( tpos ( 2, :, : ) );
p2     = squeeze ( tpos ( 3, :, : ) );

% Gets the vectors defining the triangles.
v10    = p0 - p1;
v21    = p1 - p2;
v02    = p2 - p0;

v10n   = v10 ./ sqrt ( sum ( v10 .* v10, 2 ) );
v21n   = v21 ./ sqrt ( sum ( v21 .* v21, 2 ) );
v02n   = v02 ./ sqrt ( sum ( v02 .* v02, 2 ) );

% Calculates the intersection of each height and each side.
pH0    = sum ( v10 .* v21n, 2 ) .* v21n + p1;
pH1    = sum ( v21 .* v02n, 2 ) .* v02n + p2;
pH2    = sum ( v02 .* v10n, 2 ) .* v10n + p0;

% Gets the vector defining each height.
vH0    = p0 - pH0;
vH1    = p1 - pH1;
vH2    = p2 - pH2;

% Corrects the vectors by its norm-2.
vH0   = vH0 ./ sum ( vH0 .* vH0, 2 );
vH1   = vH1 ./ sum ( vH1 .* vH1, 2 );
vH2   = vH2 ./ sum ( vH2 .* vH2, 2 );

% Extends the heights to match the integration points.
pH     = cat ( 3, pH0, pH1, pH2 );
pH     = permute ( pH, [ 4 1 2 3 ] );
pH     = repmat ( pH, nint, 1, 1, 1 );
pH     = reshape ( pH, nint * ntri, 3, 3 );

vH     = cat ( 3, vH0, vH1, vH2 );
vH     = permute ( vH, [ 4 1 2 3 ] );
vH     = repmat ( vH, nint, 1, 1, 1 );
vH     = reshape ( vH, nint * ntri, 3, 3 );


% Calculates the area of each element.
tnor   = cross ( p1 - p0, p2 - p0, 2 );
tnor   = squeeze ( tnor );
tarea  = sqrt ( sum ( tnor .* tnor, 2 ) ) / 2;
tnor   = tnor ./ ( 2 * tarea );

% Calculates the integration points for each element.
gpos   = gposn * tpos ( :, : );
gpos   = reshape ( gpos, nint * ntri, 3 );

% Generates a matrix to translate integration points to triangles.
tindex = repmat ( 1: ntri, nint, 1 );
pindex = 1: ntri * nint;
g2t    = sparse ( tindex, pindex, repmat ( gwein, 1, ntri ) );


% Extends the normals to match the integration points.
gnor   = reshape ( tnor, 1, ntri, 3 );
gnor   = repmat  ( gnor, nint, 1, 1 );
gnor   = reshape ( gnor, nint * ntri, 3 );

% Calculates the gradient of the potential by each dipole.
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


% Calculates the potential at each integration point.
gpot   = mycd_potential ( dippos, gpos, cond );

% Combines all the integration points for each triangle.
tpot   = g2t * gpot;


% Multiplies the results by twice the area of the element.
tdpot  = tdpot .* 2 .* tarea;
tpot   = tpot .* 2 .* tarea;


% Reshapes the gradient of the potential as 3 * ntri x 3 * ndip.
tdpot  = permute ( tdpot, [ 1 3 2 ] );
tdpot  = reshape ( tdpot, 3 * ntri, 3 * ndip );

% Adds the gradient of the potential to the corresponding nodes.
t2n    = sparse ( mesh.tri, 1: 3 * ntri, 1 );
ndpot  = t2n * tdpot;


% Gets the total number of nodes and elements.
tnod   = size ( cat ( 1, headmodel.bnd.pos ), 1 );
ttri   = size ( cat ( 1, headmodel.bnd ( 1: end - 1 ).tri ), 1 );

% Initializes the sources matrix.
srcmat = zeros ( tnod + ttri, 3 * ndip );

% Calculates the indices for the potential and gradient matrices.
nindex = ( 1: npos );
tindex = ( 1: ntri ) + npos;

% Stores the matrices.
srcmat ( nindex, : ) = ndpot;
srcmat ( tindex, : ) = -tpot;
