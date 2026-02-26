function sloreta = mylrt_sloreta ( leadfield, alpha )

% Calculates the inverse operator using sLORETA.
% 
% sloreta = my_eloreta ( leadfield, alpha )
% 
% * leadfield is a nsen x nori x ndip matrix.
%   This shape is the output of executing 'cat ( 3, grid.leafield {:} )'.
% * alpha is the regularization factor in parts per one of the trace.
%   Default is 0.05, or 5% of the average sensor power.
% 
% * sloreta is the inverse operator, with dimensions nori x ndip x nsen.

% Based on FieldTrip functions:
% * ft_sloreta by Robert Oostenveld & Sarang Dalal
%
% Based on papers (citation sugested):
% * Pascual-Marqui 2002 Methods Find. Exp. Clin. Pharmacol. 24.5.12.
% * Pascual-Marqui 2007 arXiv 0710.3341. http://arxiv.org/pdf/0710.3341

% Sets the default parameters, if required.
if nargin < 2; alpha = 0.05; end


% Gets the dimensions of the data.
[ nsens, nori, ndip ] = size ( leadfield );


% Calculates the symmetric matrix C (Eq. 19).
KKt = leadfield ( :, : ) * leadfield ( :, : )';
aH  = alpha * trace ( KKt ) / nsens * ( eye ( nsens ) - 1 / nsens );
C   = pinv ( KKt + aH );


% Reserves memory for the inverse operator.
sloreta = zeros ( nori, ndip, nsens );

% Goes through each source position.
for dindex = 1: ndip
    
    % Gets the lead field for this source position.
    slead  = leadfield ( :, :, dindex );
    
    % Calculates the square root inverse for this source position.
%     isrmat = pinv ( sqrtm ( slead' * C * slead ) );
    srimat = sqrtm ( pinv ( slead' * C * slead ) );
    
    % Calculates the inverse operator (Eq. 15).
    sloreta ( :, dindex, : ) = srimat * slead' * C;
end
