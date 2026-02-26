function [ dm, Pm, E1, in ] = NFT_dmp (P, V, E )

% looks for if P is inside the mesh Coord, Elem or not
% Pm is the point on the mesh
% dm is the distance
% el is the element of Pm
% in = inside (bool)
% works for LINEAR MESH

% Based on NFT 2.3 functions:
% * utilmesh_dist_mesh_point
% * mesh_elementsofthenodes


% Gets the (at least) three nodes of the mesh nearer to the given point.
d = sum ( bsxfun ( @minus, V, P ) .^ 2, 2 );
D = sort ( d );
N = find ( d <= D (3) );

% Gets the list of poligons using those nodes.
E1 = find ( any ( ismember ( E, N ), 2 ) );

% Finds the poligon nearest to the point.
dm = zeros ( length ( E1 ), 1 );
Pm = zeros ( length ( E1 ), 3 );

for i = 1: length ( E1 )
   Pa = V ( E ( E1 ( i ), 1 ), : );
   Pb = V ( E ( E1 ( i ), 2 ), : );
   Pc = V ( E ( E1 ( i ), 3 ), : );
   
   [ D, Pp ] = NFT_dpt ( Pa, Pb, Pc, P );
   dm ( i )    = D;
   Pm ( i, : ) = Pp;
end

% Selects the nearest poligon.
[ dm, k ] = min ( abs ( dm ) );
Pm = Pm ( k, : );
E1 = E1 ( k );

% If the point is in the surface, moves Pm slightly to the outside.
if Pm == P
    Pm = Pm + ( Pm - mean ( V, 1 ) ) / norm ( Pm - mean ( V, 1 ) ) * 1e-12;
end

% % Checks if the point is at the same side of the mesh that its centroid.
% in = ( Pm - mean ( V, 1 ) ) * ( Pm - P )' >= 0;

% Checks that the solid angle of the mesh respect to the point is 4pi.
in = abs ( sum ( solid_angle ( bsxfun ( @minus, V, P ), E ) ) ) > 2 * pi;

% % Calculates the proyection of the point respect to the face normal.
% normal = cross ( V ( E ( E1, 1 ), : ) - V ( E ( E1, 2 ), : ), V ( E ( E1, 2 ), : ) - V ( E ( E1, 3 ), : ) );
% in = dot ( P - Pm, normal ) < 0;



% in0 = abs ( sum ( solid_angle ( bsxfun ( @minus, V, P ), E ) ) ) > 2 * pi;
% in1 = ( Pm - mean ( V, 1 ) ) * ( Pm - P )' >= 0;
% normal = cross ( V ( E ( E1, 1 ), : ) - V ( E ( E1, 2 ), : ), V ( E ( E1, 2 ), : ) - V ( E ( E1, 3 ), : ) );
% in2 = dot ( P - Pm, normal ) < 0;
% 
% fprintf ( 1, 'Solid angle: %i.\nCentroid: %i.\nNormal: %i.\n\n', in, in1, in2 );
% if ~isequal ( in0, in1, in2 ), pause, end





function [ D, Pp ] = NFT_dpt ( Va, Vb, Vc, P )
% finds the minimum distance of a point P to triangle Va, Vb, Vc
% difference from DistTrianglePoint 
% doesn't look if the projection of the point is in the triangle or on the edge 
% of the triangle otherwise MinD is 1000

% Based on NFT 2.3 functions:
% * warping_disttrianglepoint by Zeynep Akalin Acar

% Defines the plane of the triangle using its normal.
n1 = ( Va (2) - Vb (2) ) * ( Vc (3) - Vb (3) ) - ( Va (3) - Vb (3) ) * ( Vc (2) - Vb (2) );
n2 = ( Va (3) - Vb (3) ) * ( Vc (1) - Vb (1) ) - ( Va (1) - Vb (1) ) * ( Vc (3) - Vb (3) );
n3 = ( Va (1) - Vb (1) ) * ( Vc (2) - Vb (2) ) - ( Va (2) - Vb (2) ) * ( Vc (1) - Vb (1) );
n  = [ n1 n2 n3 ] / norm ( [ n1 n2 n3 ] );

% Solves the equation of the plane.
% n1 * x + n2 * y + n3 * z + d = 0 => dot ( n, p(x,y,z) ) + d = 0
d = -n * Va';

% Gets the minimum distance from P to the parallel plane.
D = n * P' + d;

% Gets the nearest point to P in the plane of the triangle.
Pp = P - D * n;


% Checks if the point is inside the triangle.

% Logic:
% * All the cross products are normal to the plane.
% * ABxAC, BCxBA and CAxCB always have the same sign.
% * If P is inside ABC, ABxAC and ABxAP must have the same sign.
% Then:
% * If P is inside ABC, ABxAP, BCxBP and CAxCP must have the same sign.
% * Check only one not-zero dimension of the cross product is enough.

% Calculates the cross product over the first not-zero direction.
if n (1) ~= 0
    
    % If the cross product is possitive the result is 1. Otherwise is 0.
    c1 = ( Va (2) - Vb (2) ) * ( Va (3) - Pp (3) ) > ( Va (3) - Vb (3) ) * ( Va (2) - Pp (2) );
    c2 = ( Vb (2) - Vc (2) ) * ( Vb (3) - Pp (3) ) > ( Vb (3) - Vc (3) ) * ( Vb (2) - Pp (2) );
    c3 = ( Vc (2) - Va (2) ) * ( Vc (3) - Pp (3) ) > ( Vc (3) - Va (3) ) * ( Vc (2) - Pp (2) );
    
elseif n (2) ~= 0
    c1 = ( Va (3) - Vb (3) ) * ( Va (1) - Pp (1) ) > ( Va (1) - Vb (1) ) * ( Va (3) - Pp (3) );
    c2 = ( Vb (3) - Vc (3) ) * ( Vb (1) - Pp (1) ) > ( Vb (1) - Vc (1) ) * ( Vb (3) - Pp (3) );
    c3 = ( Vc (3) - Va (3) ) * ( Vc (1) - Pp (1) ) > ( Vc (1) - Va (1) ) * ( Vc (3) - Pp (3) );
    
else
    c1 = ( Va (1) - Vb (1) ) * ( Va (2) - Pp (2) ) > ( Va (2) - Vb (2) ) * ( Va (1) - Pp (1) );
    c2 = ( Vb (1) - Vc (1) ) * ( Vb (2) - Pp (2) ) > ( Vb (2) - Vc (2) ) * ( Vb (1) - Pp (1) );
    c3 = ( Vc (1) - Va (1) ) * ( Vc (2) - Pp (2) ) > ( Vc (2) - Va (2) ) * ( Vc (1) - Pp (1) );
end

% If the point is outisde the triangle takes the nearest edge point.
if ~isequal ( c1, c2, c3 )
    
   % Gets the distance between the point and the three edges.
   [ Di, Ppi ] = NFT_dps ( P, Va, Vb );
   D (1) = Di;
   Pp ( 1, : ) = Ppi;
   
   [ Di, Ppi ] = NFT_dps ( P, Vb, Vc );
   D (2) = Di;
   Pp ( 2, : ) = Ppi;
   
   [ Di, Ppi ] = NFT_dps ( P, Vc, Va );
   D (3) = Di;
   Pp ( 3, : ) = Ppi;
   
   % Keeps the nearest point.
   [ D, v ] = min ( abs ( D ) );
   Pp = Pp ( v, : );
end

% Gets the absolute value of the distance.
D = abs ( D );



function [ D, Pp ] = NFT_dps ( P, P1, P2 )
% Distance between a point and a segment.
% Finds distance between the point P and the line segment P1P2.

% Based on NFT 2.3 functions:
% * DistPointLineSegment

% Gets the point as the projection of PP1 in the direction of P1P2.
Vu = ( P2 - P1 ) / norm ( P2 - P1 );
Pp = P1 + Vu * ( Vu * ( P - P1 )' );

% If the point is beyond the extremes, replaces it by the extreme.
if norm ( P1 - Pp ) > norm ( P2 - P1 ), Pp = P2; end
if norm ( P2 - Pp ) > norm ( P2 - P1 ), Pp = P1; end

% Gets the distance to the original point.
D = norm ( P - Pp );
