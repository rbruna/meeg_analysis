function transform = my_rigid_transform ( set1, set2 )

% Based on:
% * Arun et al. 1987 "Least-Squares Fitting of Two 3-D Point Sets"
%   IEEE Trans. Pattern Anal. Mach. Intell. PAMI-9(5):698-700.

% Checks the input.
if nargin ~= 2
    error ( 'Requires two input arguments.' )
elseif size ( set1, 1 ) ~=3 || size ( set2, 1 ) ~=3
    error ( 'Input point clouds must be a 3xN matrix.' )
elseif ~isequal ( size ( set1 ), size ( set2 ) )
    error ( 'Input point clouds must be of the same size.' )
elseif size ( set1, 2 ) < 3
    error ( 'At least 3 point matches are needed.' )
end


% Gets the centers of the sets of points to calculate shifting.
center1   = mean ( set1, 2 );
center2   = mean ( set2, 2 );

% Centers the sets of points in the origin to calculate rotation.
set1      = bsxfun ( @minus, set1, center1 );
set2      = bsxfun ( @minus, set2, center2 );

% Calculates the rotation from the set of points 1 to the set of points 2.
[ v, ~, u ] = svd ( set1 * set2' );

% Generates the rotation matrix.
rot = v * u';

% Makes sure that there is no reflexion.
if det ( rot ) < 0
    v ( :, 3 ) = -v ( :, 3 );
    rot = v * u';
end

% Builds the transformation matrix.
transform = eye (4);
transform ( 1: 3, 1: 3 ) = rot;
transform ( 1: 3, 4 ) = center1 - rot * center2;
