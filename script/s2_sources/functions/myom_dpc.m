function [ dist, weight ] = myom_dpc ( mesh, point )

% Function to get the closest triangle to a point.
% 
% Based on OpenMEEG 2.1 functions:
% * dpc by G. Adde, M. Clerc, A. Gramfort, R. Keriven, J. Kybic,
%   P. Landreau, T. Papadopoulo, E. Olivi.
% 
% Based on publications:
% * Danielsson P.-E. 1980 Comput. Vision. Graph. 14.227-48.


% Rationale:
% When projecting the poing over the plane defined by the triangle, we have
% three possible scenarios:
% a) The projection is inside the triangle.
% b) The projection is outside the triangle. 
% 
% In case b) we can project the original projection over the closest edge.
% b1) The projection of the original projection is inside the edge.
% b2) The projection of the original projection is outside the edge.
%
% The calculation of the weights and the distance is different:
% In scenario a) we need to consider all three nodes.
% In scenario b1) we need to consider the two nodes of the edge.
% In scenario b2) we only consider the closest node.
% 
% Using Danielsson formula all the weights must add up to 1.
% We can know the scenario using the three-node weights:
% In scenario a) all weights are larger than 0.
% In scenario b1) one weight (the opposite node) is smaller than 0.
% In scenario b2) two weights (the farther nodes) are smaller than 0.


% Gets the surface size.
ntri    = size ( mesh.tri, 1 );

% Gets the triangles as a 3D matrix.
postri  = mesh.pos ( mesh.tri (:), : );
postri  = reshape ( postri, [], 3, 3 );
postri  = permute ( postri, [ 1 3 2 ] );


% Assumes the projection of the point is inside the faces.
aweight = ones  ( ntri, 3 );
nweight = sum   ( aweight, 2 );

% Initializes the matrix for the weights and the distance.
weight  = zeros ( ntri, 3 );
dist    = zeros ( ntri, 1 );

% The closes point is on the face.
if any ( nweight == 3 )
    
    % Takes the first vertex as the pivot.
    pivpos  = postri ( nweight == 3, :, 1 );
    
    % Defines the vectors of interest.
    vectri  = postri ( nweight == 3, :, 2: 3 ) - pivpos;
    vecpnt  = point - pivpos;
    
    
    % Sets up the linear system.
    b_vec1  = sum ( vectri ( :, :, 1 ) .* vecpnt, 2 );
    b_vec2  = sum ( vectri ( :, :, 2 ) .* vecpnt, 2 );
    a_mat_d = sum ( vectri .* vectri, 2 );
    a_mat11 = a_mat_d ( :, :, 1 );
    a_mat22 = a_mat_d ( :, :, 2 );
    a_mat12 = sum ( vectri ( :, :, 1 ) .* vectri ( :, :, 2 ), 2 );
    
    % Calculates alpha using an explicit inversion of the A matrix.
    a_det   = a_mat11 .* a_mat22 - a_mat12 .* a_mat12;
    alpha1  = ( b_vec1 .* a_mat22 - b_vec2 .* a_mat12 ) ./ a_det;
    alpha2  = ( b_vec2 .* a_mat11 - b_vec1 .* a_mat12 ) ./ a_det;
    
    % Calculates the distance from the point to the element.
    dist3   = alpha1 .* vectri ( :, :, 1 ) + alpha2 .* vectri ( :, :, 2 ) - vecpnt;
    
    
    % Generates the weight matrix in three-column form.
    weight3 = cat ( 2, 1 - ( alpha1 + alpha2 ), alpha1, alpha2 );
    
    % Stores the weights and the distances.
    weight ( nweight == 3, : ) = weight3;
    dist   ( nweight == 3 ) = sqrt ( sum ( dist3 .^ 2, 2 ) );
end


% Disables the vertices with alpha smaller than zero.
aweight = weight > 0;
nweight = sum ( aweight, 2 );


% The closes point is on an edge.
if any ( nweight == 2 )
    
    % Gets the index to the active vertices.
    [ index, ~ ] = find ( aweight ( nweight == 2, : )' );
    index   = reshape ( index, 2, [] )';
    
    % Gets the vertices.
    posseg  = postri ( nweight == 2, :, : );
    posseg  ( index ( :, 1 ) == 2, :, 1 ) = posseg ( index ( :, 1 ) == 2, :, 2 );
    posseg  ( index ( :, 2 ) == 3, :, 2 ) = posseg ( index ( :, 2 ) == 3, :, 3 );
    posseg  = posseg ( :, :, 1: 2 );
    
    
    % Takes the first vertex as the pivot.
    pivpos  = posseg ( :, :, 1 );
    
    % Defines the vectors of interest.
    vecseg  = posseg ( :, :, 2 ) - pivpos;
    vecpnt  = point - pivpos;
    
    
    % Calculates the first alpha value.
    alpha1  = sum ( vecseg .* vecpnt, 2 ) ./ sum ( vecseg .* vecseg, 2 );
    
    % Calculates the distance from the point to the edge.
    dist2   = alpha1 .* vecseg ( :, :, 1 ) - vecpnt;
    
    
    % Generates the weight matrix in three-column form.
    weight2 = zeros ( sum ( nweight == 2 ), 3 );
    weight2 ( index ( :, 1 ) == 1, 1 ) = 1 - alpha1 ( index ( :, 1 ) == 1 );
    weight2 ( index ( :, 1 ) == 2, 2 ) = 1 - alpha1 ( index ( :, 1 ) == 2 );
    weight2 ( index ( :, 2 ) == 2, 2 ) = alpha1 ( index ( :, 2 ) == 2 );
    weight2 ( index ( :, 2 ) == 3, 3 ) = alpha1 ( index ( :, 2 ) == 3 );
    
    % Stores the weights and the distances.
    weight ( nweight == 2, : ) = weight2;
    dist   ( nweight == 2 ) = sqrt ( sum ( dist2 .^ 2, 2 ) );
end


% Disables the vertices with alpha smaller than zero.
aweight = weight > 0;
nweight = sum ( aweight, 2 );


% The closes point is a vertex.
if any ( nweight == 1 )
    
    % Gets the index to the active vertices.
    [ index, ~ ] = find ( aweight ( nweight == 1, : )' );
    index   = reshape ( index, 1, [] )';
    
    % Gets the vertex.
    posnod  = postri ( nweight == 1, :, : );
    posnod ( index ( :, 1 ) == 2, :, 1 ) = posnod ( index ( :, 1 ) == 2, :, 2 );
    posnod ( index ( :, 1 ) == 3, :, 1 ) = posnod ( index ( :, 1 ) == 3, :, 3 );
    posnod  = posnod ( :, :, 1 );
    
    % Takes the vertex as the pivot.
    pivpos  = posnod;
    
    % Defines the vector of interest.
    vecpnt  = point - pivpos;
    
    % Calculates the distance from the point to the vertex.
    dist1   = vecpnt;
    
    
    % Generates the weight matrix in three-column form.
    weight1 = aweight ( nweight == 1, : );
    
    % Stores the weights and the distances.
    weight ( nweight == 1, : ) = weight1;
    dist   ( nweight == 1 ) = sqrt ( sum ( dist1 .^ 2, 2 ) );
end
