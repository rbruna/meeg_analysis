function tpot = myom_srctpot ( dippos, tpos, gint, cond )

% Sets the default level of Gaussian integration.
if nargin < 3
    gint   = 4;
end

% Gets the normalized Gaussian integration points.
[ gposn, gwein ] = myom_gaussian_tri ( gint );
nint   = numel ( gwein );


% Gets the dimensions of the data.
ntri   = size ( tpos, 2 );

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
tarea  = sqrt ( sum ( tnor .* tnor, 2 ) ) / 2;


% Calculates the potential at each integration point.
gpot   = mycd_potential ( dippos, gpos, cond );


% Combines all the integration points for each triangle.
tpot   = g2t * gpot;


% Multiplies the results by twice the area of the element.
tpot   = tpot .* 2 .* tarea;
