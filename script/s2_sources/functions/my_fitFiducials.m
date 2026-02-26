function transform = my_fitFiducials ( static, moving )

% Checks the inputs.
if nargin ~= 2
    error ( 'This function requires two input arguments.' );
end
if ...
        ~isfield ( static,     'fid' )   || ...
        ~isfield ( static.fid, 'label' ) || ...
        ~isfield ( static.fid, 'pos' )   || ...
        ~isfield ( moving,     'fid' )   || ...
        ~isfield ( moving.fid, 'label' ) || ...
        ~isfield ( moving.fid, 'pos' )
    error ( 'This functions requires fiducial data as input.' );
end
if size ( static.fid.pos, 2 ) ~= 3 || size ( moving.fid.pos, 2 ) ~= 3
    error( 'Fiducial position is not 3D.' );
end

% Gets the list of shared fiducials.
fiducials = intersect ( static.fid.label, moving.fid.label );

% If less than 3 shared fiducials rises an error.
if numel ( fiducials ) < 3
    error ( 'Both inputs must share at least 3 fiducials.' );
end

% Initializes the coulds of points.
x = zeros ( numel ( fiducials ), 3 );
y = zeros ( numel ( fiducials ), 3 );

% Gets the shared fiducials' position.
for findex = 1: numel ( fiducials )
    x ( findex, : ) = static.fid.pos ( strcmp ( static.fid.label, fiducials ( findex ) ), : );
    y ( findex, : ) = moving.fid.pos ( strcmp ( moving.fid.label, fiducials ( findex ) ), : );
end

% Fits both clouds of points.
transform = fitPoints ( x, y );


function transform = fitPoints ( x, y )
% FITPOINT
%   T = FITPOINT(X, Y) estimates the rigid transformation
%   that best aligns x with y (in the least-squares sense).
%  
%   Reference: "Estimating Rigid Transformations" in 
%   "Computer Vision, a modern approach" by Forsyth and Ponce (1993), page 480
%   (page 717(?) of the newer edition)
%
%   Input:
%       X: Nx3, N 3-D points (N>=3)
%       Y: Nx3, N 3-D points (N>=3)
%
%   Output
%       T: the rigid transformation that aligns x and y as:  xh' = T * yh'
%          (h denotes homogenous coordinates)  
%          (corrspondence between points x(:,i) and y(:,i) is assumed)
%
% Based on function:
% * estimateRigidTransform by Babak Taati, 2003 (revised 2009).

pointCount = size ( x, 1 );

% Centers both clouds in 0.
x_centroid = mean ( x, 1 );
y_centroid = mean ( y, 1 );
x_centrized = bsxfun ( @minus, x, x_centroid );
y_centrized = bsxfun ( @minus, y, y_centroid );

% Gets the differences in position.
R12 = y_centrized - x_centrized;
R21 = x_centrized - y_centrized;
R22 = y_centrized + x_centrized;
R22 = crossTimesMatrix ( R22 );

A = zeros ( pointCount, 4, 4 );
A ( :, 1,      2: end ) = R12;
A ( :, 2: end,      1 ) = R21;
A ( :, 2: end, 2: end ) = R22;

for pindex = 1: pointCount
    A ( pindex, :, : ) = squeeze ( A ( pindex, :, : ) )' * squeeze ( A ( pindex, :, : ) );
end
A = squeeze ( sum ( A, 1 ) );

% Calculates the diference in rotation.
[ ~, ~, V ] = svd ( A );
rotation    = quat2rot ( V ( :, 4 ) );

% Contructs the matrices in three steps.
% First centers the moving points in 0.
transform1 = [eye(3,3), -y_centroid' ; 0 0 0 1];

% Rotates the moving points to fit the static points' orientation.
transform2 = [ rotation, [0; 0; 0]; 0 0 0 1];

% Moves the moving points to the static points' position.
transform3 = [eye(3,3), x_centroid' ;  0 0 0 1];

% The result is the product of all the movements.
transform  = transform3 * transform2 * transform1;
                    
               
                    
function V_times = crossTimesMatrix(V)
% CROSSTIMESMATRIX
%   V_TIMES = CROSSTIMESMATRIX(V) returns a 1x3x3 (or a series of 1x3x3) cross times matrices of input vector(s) V
% 
%   Input:
%       V a Nx3 matrix, rpresenting a series of 1x3 vectors
% 
%   Output:   
%       V_TIMES (Vx) a series of 3x3 matrices where V_times(i,:,:) is the Vx matrix for the vector V(i,:)
% 
% Based on:
% * crossTimesMatrix by Babak Taati, 2003 (revised 2009).

[a,b] = size(V);
V_times = zeros ( a, 3, b );

V_times ( :, 1, 2 ) = -V ( :, 3 );
V_times ( :, 1, 3 ) =  V ( :, 2 );

V_times ( :, 2, 1 ) =  V ( :, 3 );
V_times ( :, 2, 3 ) = -V ( :, 1 );

V_times ( :, 3, 1 ) = -V ( :, 2 );
V_times ( :, 3, 2 ) =  V ( :, 1 );


function R = quat2rot(Q)
% QUAT2ROT
%   R = QUAT2ROT(Q) converts a quaternion (4x1 or 1x4) into a 3x3 rotation mattrix
%
%   reference: google!
%
% Based on:
% * quat2rot by Babak Taati, 2003 (revised 2009).

q0 = Q(1);
q1 = Q(2);
q2 = Q(3);
q3 = Q(4);

R(1,1)  = q0*q0  +  q1*q1  -  q2*q2  -  q3*q3;
R(1,2)  = 2 * (q1*q2  -  q0*q3);
R(1,3)  = 2 * (q1*q3  +  q0*q2);

R(2,1)  = 2 * (q1*q2  +  q0*q3);
R(2,2)  = q0*q0  -  q1*q1  +  q2*q2  -  q3*q3;
R(2,3)  = 2 * (q2*q3  -  q0*q1);

R(3,1)  = 2 * (q1*q3  -  q0*q2);
R(3,2)  = 2 * (q2*q3  +  q0*q1);
R(3,3)  = q0*q0  -  q1*q1  -  q2*q2  +  q3*q3;
