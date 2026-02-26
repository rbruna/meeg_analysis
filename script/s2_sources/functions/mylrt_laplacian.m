function lapmat = mylrt_laplacian ( src )

% Calculates the *inverse squared* Laplacian of the source space according
% to LORETA defintion.

% Based on papers (citation sugested):
% * Pascual-Marqui, Michel & Lehmann 1994 Int. J. Psychophysiol. 18.49-65.
% * Skrandies et al. 1995 ISBET Newslett. 6.21–5.
% * Pascual-Marqui 1999 Int. J. Bioelectromagn. 1.75-86.


% Gets the number of source positions.
nsrc  = size ( src, 1 );

% If the input is a grid definition, looks for neighbors.
if size ( src, 2 ) == 3
    
    % Generates a distance matrix.
    vect   = permute ( src, [ 1 3 2 ] ) - permute ( src, [ 3 1 2 ] );
    dist   = sqrt ( sum ( vect .^ 2, 3 ) );
    
    % Defines the "neighbor distance".
    dthre  = min ( dist ( dist > 0 ) );
    
    % Gets the neighbor matrix from the distance matrix.
    neighs = abs ( dist - dthre ) < 1e-6 * dthre;
    
% Otherwise the input is a neighbor definition or a distance matrix.
else
    
    % Gets the neighbor definition.
    neighs = abs ( src );
    
    % Binarizes the neighbor definition, if required.
    dthre  = min ( neighs ( neighs > 0 ) );
    neighs = neighs == dthre;
end

% If the size of the matrix is not nsrouces rises an error.
if size ( neighs, 2 ) ~= nsrc
    error ( 'Unknown input matrix.' )
end


% Initializes the Laplacian matrix to a diagonal.
lapmat = eye ( nsrc );

% Goes through each source position.
for sindex = 1: nsrc
    
    % Gets the list of neighbors to the current source position.
    nindex = neighs ( sindex, : );
    nneigh = sum ( nindex );
    
    % Calculates the weight for each neighbor (Eq. 2, 2', and 2'', 1995).
%     nweight = 1 / 6;
%     nweight = 1 / nneigh;
    nweight = ( 6 + nneigh ) / ( 12 * nneigh );
    
    % Sets the weight of the neighors.
    lapmat ( sindex, nindex ) = nweight;
end

% % Escales the Laplacian matrix by 6 / distance.
% lapmat  = 6 * lapmat / ( dthre * dthre );

% Calculates the inverse of the squared Laplacian matrix.
lapmat = abs ( inv ( lapmat' * lapmat ) );
