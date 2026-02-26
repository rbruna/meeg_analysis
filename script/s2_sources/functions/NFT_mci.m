function P = NFT_mci ( P, V, E)
% mesh_check_intersection() - Detects and corrects mesh intersections
%
% Usage:
%   >> P = mesh_check_intersection(P, V, E);
%
% Inputs:
%   P:    Inner mesh nodes.
%   V, E: Outter mesh.

% Based on NFT 2.3 functions:
% * mesh_check_intersection
% * utilmesh_check_source_space

% Goes though all the points.
for ipoint = 1: size ( P, 1 )
    
    % Gets the distance from the point to the mesh.
    p1 = P ( ipoint, : );
    [ dm, Pm, ~, in ] = NFT_dmp ( p1, V, E );
    
    % If the point is outside the mesh, moves it to the inside.
    if ~in
        
        % Moves the point to the mesh point, 1 mm inside the surface.
        nor = -( Pm - p1 ) / norm ( Pm - p1 );
        pn  = Pm - 1.5 * nor;
        [ ~, ~, ~, in ] = NFT_dmp ( pn, V, E );
        
        % If the point is still in the outside rises an error.
        if ~in
            fprintf ( 2, 'Error! Point %i outside the outer mesh.\n', ipoint );
        end
        P ( ipoint, : ) = pn;
        
    % If the point is too close to the mesh, moves it to the inside.
    elseif dm < 1.5
        
        % Moves the point to the mesh point, 1 mm inside the surface.
        nor = ( Pm - p1 ) / norm ( Pm - p1 );
        pn  = Pm - 1.5 * nor;
        [ ~, ~, ~, in ] = NFT_dmp ( pn, V, E );
        
        % If the point has moved to the outside rises an error.
        if ~in
            fprintf ( 2, 'Error! Point %i outside the outter mesh.\n', ipoint );
        end
        P ( ipoint, : ) = pn;
    end    
end
