function srcmat = myom_dsm ( headmodel, grid, gint, adapt )

% Based on OpenMEEG functions:
% * assemble_DipSourceMat by Alexandre Gramfort
% * operatorDipolePot by Alexandre Gramfort
% * operatorDipolePotDer by Alexandre Gramfort


% Sets the default level of Gaussian integration.
if nargin < 3 || isempty ( gint ) || isnan ( gint )
    gint   = 4;
end

% By default, uses adaptive integration.
if nargin < 4
    adapt  = true;
end


% Sanitizes the grid.
grid   = my_fixgrid ( grid );

% Extracts the dipole positions.
dippos = grid.pos ( grid.inside, : );


% Gets the information of the first surface.
nmesh  = numel ( headmodel.bnd );
mesh   = headmodel.bnd (1);
cond   = headmodel.cond (1);

% Gets the total number of nodes and elements.
tnod   = size ( cat ( 1, headmodel.bnd.pos ), 1 );
ttri   = size ( cat ( 1, headmodel.bnd ( 1: end - 1 ).tri ), 1 );


% Gets the dimensions of the data.
ntri   = size ( mesh.tri, 1 );
npos   = size ( mesh.pos, 1 );
ndip   = size ( dippos, 1 );

% Initializes the sources matrix.
srcmat = zeros ( tnod + ttri, 3 * ndip );


% Extracts the vertices for each triangle.
tpos   = mesh.pos ( mesh.tri', : );
tpos   = reshape ( tpos, 3, ntri, 3 );

% Extracts the position of the 1st, 2nd and 3rd nodes of each triangle.
p0     = squeeze ( tpos ( 1, :, : ) );
p1     = squeeze ( tpos ( 2, :, : ) );
p2     = squeeze ( tpos ( 3, :, : ) );

% Calculates the heights of the triangles.
[ pH, vH ] = myom_trih ( p0, p1, p2 );


% Calculates the potentials and its normal derivative at each element.
tdpot  = myom_srctdpot ( dippos, tpos, gint, pH, vH );

% Proceeds with the adaptative integration, if requested.
if adapt %&& ndip == 1
    tdpot  = myom_asrctdpot ( tdpot, dippos, tpos, gint, pH, vH );
end

% Reshapes the gradient of the potential as 3 * ntri x 3 * ndip.
tdpot  = permute ( tdpot, [ 1 3 2 ] );
tdpot  = reshape ( tdpot, 3 * ntri, 3 * ndip );

% Adds the gradient of the potential to the corresponding nodes.
t2n    = sparse ( mesh.tri, 1: 3 * ntri, 1 );
ndpot  = t2n * tdpot;

% Calculates the indices for the source matrix.
nindex = ( 1: npos );

% Stores the matrix.
srcmat ( nindex, : ) = ndpot;


% If more than one mesh calculates the normal current.
if nmesh > 1
    
    % Calculates the potentials and its normal derivative at each element.
    tpot   = myom_srctpot ( dippos, tpos, gint, cond );
    
    % Proceeds with the adaptative integration, if requested.
    if adapt %&& ndip == 1
        tpot   = myom_asrctpot ( tpot,  dippos, tpos, gint, cond );
    end
    
    % Calculates the indices for the source matrix.
    tindex = ( 1: ntri ) + tnod;
    
    % Stores the matrix.
    srcmat ( tindex, : ) = -tpot;
end
