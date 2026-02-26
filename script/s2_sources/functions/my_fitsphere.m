function [ center, radius ] = my_fitsphere ( points )

% FITSPHERE fits the centre and radius of a sphere to a set of points
% using Taubin's method.
%
% Use as
%       [center,radius] = fitsphere(points)
% where
%   points  = Nx3 matrix with the Carthesian coordinates of the surface points
% and
%   center  = the center of the fitted sphere
%   radius  = the radius of the fitted sphere

% Based on FieldTrip 20160222 (from SPM) functions:
% * fitsphere by Jean Daunizeau

% Copyright (C) 2009, Jean Daunizeau (for SPM)


% Gets the number of points.
npoints = size ( points, 1 );

% Calculates the obsolute distance to each point.
dist    = sum ( points .^ 2, 2 );
% dummy   = cat ( 2, dist, points );
dummy   = cat ( 2, dist, points, ones ( npoints, 1 ) );

% Creates the design matrices.
% M = zeros (5);
% M ( 1: 4, 1: 4 ) = dummy' * dummy;
% M ( 5, 1: 4 )    = sum ( dummy, 1 );
% M ( 1: 4, 5 )    = sum ( dummy, 1 );
% M ( 5, 5 )       = npoints;
M = dummy' * dummy;

N = eye (5) * npoints;
N ( 1, 1 )    = 4 * sum ( dist );
N ( 2: 4, 1 ) = 2 * sum ( points, 1 );
N ( 1, 2: 4 ) = 2 * sum ( points, 1 );
N ( 5, 5 )    = 0;


% Extract eigensystem
[ vec, val ] = eig ( M );
val = diag ( val );

% If the matrix is full rank the solution is the maximum autovector.
if all ( val > eps * 5 * norm ( M ) )
    % Full rank -- min ev corresponds to solution
    % Minverse = v'*diag(1./evalues)*v;
    [ vec, val ] = eig ( M \ N );
    [ ~, idx ] = max ( diag ( val ) );
    pvec = vec ( :, idx )';
else
    % Rank deficient -- just extract nullspace of M
    % pvec = null(M)';  % this does not work reliably because of inconsistent rank definition
    pvec = vec ( :, find ( val <= eps * 5 * norm ( M ), 1 ) )';
end

if isempty ( pvec )
    warning ( 'Impossible to fit a sphere to the provided points.' );
    pvec   = zeros ( 1, 5 );
end

% Calculates the center and the radius of the sphere.
center = pvec ( 2: 4 ) / -pvec (1) / 2;
radius = sqrt ( sum ( center .^ 2 ) + pvec (5) / -pvec (1) );
