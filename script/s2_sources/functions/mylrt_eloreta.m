function eloreta = mylrt_eloreta ( leadfield, alpha, feedback )

% Calculates the inverse operator using eLORETA.
% 
% eloreta = my_eloreta ( leadfield, alpha )
% 
% * leadfield is a nsen x nori x ndip matrix.
%   This shape is the output of executing 'cat ( 3, grid.leafield {:} )'.
% * alpha is the regularization factor in parts per one of the trace.
%   Default is 0.05, or 5% of the average sensor power.
% 
% * eloreta is the inverse operator, with dimensions nori x ndip x nsen.

% Based on FieldTrip functions:
% * mkfilt_eloreta_v2 by Guido Nolte
%
% Based on papers (citation sugested):
% * Pascual-Marqui 2007 arXiv 0710.3341. http://arxiv.org/pdf/0710.3341

% Sets the defaults.
if nargin < 2; alpha = 0.05;  end
if nargin < 3, feedback = false; end

% Disables the square root warning.
warn = warning ( 'off', 'MATLAB:sqrtm:SingularMatrix' );


% Gets the dimensions of the data.
[ nsens, nori, ndip ] = size ( leadfield );

% Generates permuted versions of the lead field matrix for easy access.
lf2d  = leadfield ( :, : );
lf2dt = lf2d';
lf3d  = leadfield;
lf3dt = permute ( lf3d, [ 2 1 3 ] );


% Initializes the weight matrix and its inverse.
W  = repmat ( eye ( nori ), 1, 1, ndip );
iW = cell ( ndip, 1 );

% Iterates a maximum of 200 times.
for iindex = 1: 200
    
    % Stores the current value of the weight matrix.
    Wo = W;
    
    
    % Goes through each source position.
    for dindex = 1: ndip
        
        % Gets the weight for this source position.
        Wi = W ( :, :, dindex );
        
        % Generates the regularization matrix.
        aH = 1e-6 * trace ( Wi ) / nori * ( eye ( nori ) - 1 / nori );
%         aI = 1e-6 * trace ( Wi ) / nori * eye ( nori );
        
        % Inverts the weight matrix.
%         iW { dindex } = sparse ( pinv ( Wi ) );
        iW { dindex } = sparse ( pinv ( Wi + aH ) );
%         iW { dindex } = sparse ( pinv ( Wi + aI ) );
    end
    
    
    % Calculates the intermediate matrix M (Eq. 44).
    M  = lf2d * ( blkdiag ( iW {:} ) * lf2dt );
    
    % Generates the regularization matrix.
    aH  = alpha * trace ( M ) / nsens * ( eye ( nsens ) - 1 / nsens );
%     aI  = alpha * trace ( M ) / nsens * eye ( nsens );
    
    % Gets the pseudo-inverse of the intermediate matris (Eq. 44).
    iM = pinv ( M + aH );
%     iM = pinv ( M + aI );
    
    
    % Goes through each source position.
    for dindex = 1: ndip
        
        % Estimates the weight matrix (Eq. 45).
        Wi = sqrtm ( lf3dt ( :, :, dindex ) * iM * lf3d ( :, :, dindex ) );
        
        % Updates the estimation.
        W ( :, :, dindex ) = Wi;
    end
    
    
    % Calculates the relative change in the weight matrix.
    rchange = norm ( W (:) - Wo (:) ) / norm ( Wo (:) );
    
    if feedback
        fprintf ( 'Iteration #%i. Relative change: %d\n', iindex, rchange )
    end
    
    % If the change is negligible stops the iterations.
    if rchange < 1e-7, break, end
end


% Reserves memory for the inverse operator.
eloreta = zeros ( nori, ndip, nsens );

% Goes through each source position.
for dindex = 1: ndip
    
    % Calculates the inverse operator (Eq. 37).
    % T = iW * L' * pinv ( L * iW * L' + alpha * H ) = iW * L' * iM
    eloreta ( :, dindex, : ) = iW { dindex } * ( lf3dt ( :, :, dindex ) * iM );
end

% Restores the warnings.
warning ( warn );
