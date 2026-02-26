function transform = my_icp ( static, moving, opts )
%  Iterative Closest Point registration algorithm for point clouds using
%  finite differences.
%
%  transform = my_icp ( static, moving, options )
%
%  inputs,
%       static : An N x 3 array with XYZ points which describe the
%                           registration target
%       moving : An M x 3 array with XYZ points which will move and
%                           be registered on the static points.
%       options : A struct with registration options:
%           options.method: 'Rigid', Translation and Rotation (default)
%                                 'Size', Rigid + Resize
%                                 'Affine', Translation, Rotation, Resize
%                                               and Shear.
%           Options.TolX: Registration Position Tollerance, default is the
%              largest side of a volume containing the points divided by 1000
%           Options.TolP: Allowed tollerance on distance error default
%              0.001 (Range [0 1])
%           Options.optimizer : optimizer used, 'fminlbfgs' (default)
%             ,'fminsearch' and 'lsqnonlin'.
%           Options.verbose : if true display registration information (default)
%
%  outputs,
%       transform : The transformation matrix to traslade the first point
%       to the second one.
%
% Based on:
% * ICP_finite by D. Kroon (University of Twente) (May 2009).

% Checks that the inputs are 3D matrices.
if size ( static, 2 ) ~=3
    error ( 'ICP_finite:inputs', 'Static points are not in m x 3 matrix form.' );
end
if size ( moving, 2 ) ~=3
    error ( 'ICP_finite:inputs', 'Moving points are not in m x 3 matrix form.' );
end

% Forces the point possitions to double precission.
static = double ( static );
moving = double ( moving );

% Permutes the data to move always the smaller cloud of points.
%%%%%%%%%%


% Initializes the user options.
if nargin < 3, opts = []; end

% Sets the default options.
options = struct ( ...
    'method',    'rigid', ...
    'TolX',      max ( max ( static ) - min ( static ) ) / 1000, ...
    'TolP',      0.001, ...
    'optimizer', 'fminlbfgs', ...
    'verbose',   false );

% Replaces the outputs for the user provided ones.
optfields = fieldnames ( options );
for oindex = 1: numel ( optfields )
    if isfield ( opts, optfields { oindex } )
        options.( optfields { oindex } ) = opts.( optfields { oindex } );
    end
end


% Initializes the translation, rotation, resize and shear parameters.
scale = cat ( 2,   1.00,   1.00,   1.00,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01,   0.01 );
par   = cat ( 2,   0.00,   0.00,   0.00,   0.00,   0.00,   0.00, 100.00, 100.00, 100.00,   0.00,   0.00,   0.00,   0.00,   0.00,   0.00 );

% If the registration method is 'size' removes the shearing.
if strcmpi ( options.method, 'size' )
    scale = scale ( 1: 9 );
    par   = par   ( 1: 9 );

% If the registration method is 'rigid' removes shearing and rotation.
elseif strcmpi ( options.method, 'rigid' )
    scale = scale ( 1: 6 );
    par   = par   ( 1: 6 );

% If the registration method is not 'affine' uses rigid transformation.
elseif ~strcmpi ( options.method, 'affine' )
    warning ( 'Unrecognized regsitration method. Using rigid transformation.' );
    scale = scale ( 1: 6 );
    par   = par   ( 1: 6 );
end


% Writes the headed of the error data.
if options.verbose
    fprintf ( 1, 'Starting the registration.\n' );
    fprintf ( 1, '  Itteration          Error\n' );
end

% Initializes the moved points and the error.
moved = moving;
fval1 = inf;

% Iterates virtually infinite times.
for iindex = 1: 1e6
    
    % Calculates the distance between the points of each cloud.
    dist      = sum ( bsxfun ( @minus, moved, permute ( static, [ 3 2 1 ] ) ) .^ 2, 2 );
    
    % Gets the nearest static point to each moving point.
    [ ~, j ]  = min ( dist, [], 3 );
    matchs    = static ( j, : );
    
    % Calculate the parameters which minimize the distance error between
    % the current closest points
    switch lower ( options.optimizer )
        case 'fminsearch'
            % Set Registration Tollerance
            optim=struct('Display','off','TolX',options.TolX);
            [par,fval]=fminsearch(@(par)affine_registration_error(par,scale,moving,matchs),par,optim);
        case 'lsqnonlin'
            % Set Registration Tollerance
            optim=optimset('Display','off','TolX',options.TolX);
            [par,fval]=lsqnonlin(@(par)affine_registration_array(par,scale,moving,matchs),par,[],[],optim);
        otherwise
            % Set Registration Tollerance
            optim=struct('Display','off','TolX',options.TolX);
            [par,fval]=fminlbfgs(@(par)affine_registration_error(par,scale,moving,matchs),par,optim);
    end
    
    % Constructs the transformation matrix.
    transform = getransformation_matrix ( par, scale );
    
    % Traslades the moving points to the new position.
    moved     = movepoints ( transform, moving );
    
    
    % Writes the error achieved in this iteration.
    if options.verbose
        fprintf ( 1, '       %5.0f  %13.6f\n', iindex, fval );
    end
    
    % Evaluates the breaking condition.
    if fval / fval1 > 1 - options.TolP
        break
    end
    
    % Stores the error achieved in this iteration.
    fval1     = fval;
end

function  [e,egrad]=affine_registration_error(par,scale,Points_Moving,Points_Static)
% Stepsize used for finite differences
delta=1e-8;

% Get current transformation matrix
M=getransformation_matrix(par,scale);

% Calculate distance error
e=calculate_distance_error(M,Points_Moving,Points_Static);

% If asked calculate finite difference error gradient
if(nargout>1)
    egrad=zeros(1,length(par));
    for i=1:length(par)
        par2=par; par2(i)=par(i)+delta;
        M=getransformation_matrix(par2,scale);
        egrad(i)=calculate_distance_error(M,Points_Moving,Points_Static)/delta;
    end
end


function [dist_total]=calculate_distance_error(M,Points_Moving,Points_Static)
% First transform the points with the transformation matrix
Points_Moved=movepoints(M,Points_Moving);
% Calculate the squared distance between the points
dist=sum((Points_Moved-Points_Static).^2,2);
% calculate the total distanse
dist_total=sum(dist);

function  [earray]=affine_registration_array(par,scale,Points_Moving,Points_Static)
% Get current transformation matrix
M=getransformation_matrix(par,scale);
% First transform the points with the transformation matrix
Points_Moved=movepoints(M,Points_Moving);
% Calculate the squared distance between the points
%earray=sum((Points_Moved-Points_Static).^2,2);
earray=(Points_Moved-Points_Static);


function Po=movepoints(M,P)
% Transform all xyz points with the transformation matrix
Po=zeros(size(P));
Po(:,1)=P(:,1)*M(1,1)+P(:,2)*M(1,2)+P(:,3)*M(1,3)+M(1,4);
Po(:,2)=P(:,1)*M(2,1)+P(:,2)*M(2,2)+P(:,3)*M(2,3)+M(2,4);
Po(:,3)=P(:,1)*M(3,1)+P(:,2)*M(3,2)+P(:,3)*M(3,3)+M(3,4);


function M=getransformation_matrix(par,scale)
% This function will transform the parameter vector in to a
% a transformation matrix

% Scale the input parameters
par=par.*scale;
switch(length(par))
    case 6  % Translation and Rotation
        M=make_transformation_matrix(par(1:3),par(4:6));
    case 9  % Translation, Rotation and Resize
        M=make_transformation_matrix(par(1:3),par(4:6),par(7:9));
    case 15 % Translation, Rotation, Resize and Shear
        M=make_transformation_matrix(par(1:3),par(4:6),par(7:9),par(10:15));
end


function M=make_transformation_matrix(t,r,s,h)
% This function make_transformation_matrix.m creates an affine
% 2D or 3D transformation matrix from translation, rotation, resize and shear parameters
%
% M=make_transformation_matrix.m(t,r,s,h)
%
% inputs (3D),
%   t: vector [translateX translateY translateZ]
%   r: vector [rotateX rotateY rotateZ]
%   s: vector [resizeX resizeY resizeZ]
%   h: vector [ShearXY, ShearXZ, ShearYX, ShearYZ, ShearZX, ShearZY]
%
% outputs,
%   M: 3D affine transformation matrix
%
% examples,
%   % 3D
%   M=make_transformation_matrix([0.5 0 0],[1 1 1.2],[0 0 0])
%
% Based on:
% * make_transformation_matrix by D. Kroon (October 2008).
% * mat_tra_3d by D. Kroon (October 2008).
% * mat_siz_3d by D. Kroon (October 2008).
% * mat_rot_3d by D. Kroon (October 2008).
% * mat_shear_3d by D. Kroon (October 2008).

% Process inputs
if(~exist('r','var')||isempty(r)), r=[0 0 0]; end
if(~exist('s','var')||isempty(s)), s=[1 1 1]; end
if(~exist('h','var')||isempty(h)), h=[0 0 0 0 0 0]; end

r = r * ( pi / 180 );
Rx = [ 1 0 0 0;
    0 cos(r(1)) -sin(r(1)) 0;
    0 sin(r(1)) cos(r(1)) 0;
    0 0 0 1 ];

Ry = [ cos(r(2)) 0 sin(r(2)) 0;
    0 1 0 0;
    -sin(r(2)) 0 cos(r(2)) 0;
    0 0 0 1 ];

Rz = [ cos(r(3)) -sin(r(3)) 0 0;
    sin(r(3)) cos(r(3)) 0 0;
    0 0 1 0;
    0 0 0 1 ];
M3 = Rx * Ry * Rz;

M2 = [ s(1) 0    0    0;
    0    s(2) 0    0;
    0    0    s(3) 0;
    0    0    0    1 ];

M4 = [ 1 h(1) h(2) 0;
    h(3) 1 h(4) 0;
    h(5) h(6) 1 0;
    0 0 0 1 ];

M1 = [ 1 0 0 t(1);
    0 1 0 t(2);
    0 0 1 t(3);
    0 0 0 1 ];

% Calculate affine transformation matrix
M = M1 * M2 * M3 * M4;
