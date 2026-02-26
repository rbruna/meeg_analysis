function loreta = mylrt_loreta ( leadfield, srcinfo, alpha )

% Calculates the inverse operator using LORETA.
% 
% loreta = my_loreta ( leadfield, grid, alpha )
% loreta = my_loreta ( leadfield, srcdist, alpha )
% loreta = my_loreta ( leadfield, srcneigh, alpha )
% 
% * leadfield is a nsen x nori x ndip matrix.
%   This shape is the output of executing 'cat ( 3, grid.leafield {:} )'.
% * grid is a nsources x 3 matrix of grid positions.
%   srcdist is a nsources x nsrouces matrix of distances between sources.
%   srcneigh is a nsources x nsrouces matrix of source neighborhood.
% * alpha is the regularization factor in parts per one of the trace.
%   Default is 0.05, or 5% of the first eigenvalue.
% 
% * loreta is the inverse operator, with dimensions nori x ndip x nsen.

% Based on papers (citation sugested):
% * Pascual-Marqui, Michel & Lehmann 1994 Int. J. Psychophysiol. 18.49-65.
% * Skrandies et al. 1995 ISBET Newslett. 6.22-8.
% * Pascual-Marqui 1999 Int. J. Bioelectromagn. 1.75-86.

% Checks the input.
if nargin < 2, error ( 'Not enough input parameters.' ), end

% Sets the default parameters, if required.
if nargin < 3, alpha = 0.05;  end


% Gets the dimensions of the data.
[ nsens, nori, ndip ] = size ( leadfield ); %#ok<ASGLU>


% Generates the spatial Laplacian matrix.
lapmat = mylrt_laplacian ( srcinfo );

% Generates permuted versions of the lead field matrix for easy access.
lf2d  = leadfield ( :, : );
lf2dt = lf2d';


% Calculates the total (squared) effect of each dipole and source.
lfpow  = leadfield .^ 2;
dippow = sum ( lfpow, 1 );
srcpow = sum ( dippow, 2 );

% Gets the sources normalization matrix.
omat   = diag ( sqrt ( srcpow (:) ) );

% Calculates the total weight matrix (Eq. 11, 1999).
wimat  = kron ( omat \ lapmat / omat, eye (3) );


% Calculates the regularization parameter, if requested.
if alpha > 0
    
    % Calculates the first eigenvalue.
    eigs   = svd ( lf2d * wimat * lf2dt );
    eig1   = eigs (1);
    
    % Gets the regularization matrix.
    aH     = alpha * eig1 * ( eye ( nsens ) - 1 / nsens );
else
    aH     = 0;
end

% Calculates the LORETA operator (Eq. 3, 1994; Eq. 9, 1999).
loreta = ( wimat * lf2dt ) * pinv ( lf2d * wimat * lf2dt + aH );
