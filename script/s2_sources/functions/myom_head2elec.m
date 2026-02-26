function weights = myom_head2elec ( headmodel, elec )

% Function to calculate the mapping between head (scalp) elements and
% electrodes.


% % Checks that the version of OpenMEEG is correct.
% myom_checkom ( '2.4' )

% Checks that the right version of OpenMEEG has been used.
if ~strncmp ( headmodel.version, '2.4', 3 )
    error ( [ ...
        'The head model was calculated using OpenMEEG version %s.\n' ...
        'These MATLAB functions require OpenMEEG version 2.4.\n' ], ...
        headmodel.version ( 1: 3 ) )
end


% Gets the electrode positions.
elepos = elec.elecpos;
nele   = size ( elepos, 1 );

% Gets the active surface mesh (the scalp).
mesh   = headmodel.bnd ( end );
npos   = size ( mesh.pos, 1 );
ntri   = size ( mesh.tri, 1 );

% Gets the total number of nodes and elements.
tpos   = sum ( arrayfun ( @(bnd) size ( bnd.pos, 1 ), headmodel.bnd ) );
ttri   = sum ( arrayfun ( @(bnd) size ( bnd.tri, 1 ), headmodel.bnd ) );

% Gets the size of the head matrix.
nsol   = tpos + ttri - ntri;

% Gets the offset the to active surface.
offset = tpos - npos;


% Initializes the nodes and weights information.
es = repmat ( 1: nele, 3, 1 );
ns = zeros ( 3, nele );
ws = zeros ( 3, nele );

% Goes through each electrode position.
for eindex = 1: nele
    
    % Gets the distance from each element.
    [ dist, weight ] = myom_dpc ( mesh, elec.elecpos ( eindex, : ) );
    
    % Gets the index of closest element.
    [ ~, index ] = min ( dist );
    
    % Gets the nodes of the element.
    nodes = offset + mesh.tri ( index, : );
    
    % Stores the nodes and weights for this element.
    ns ( :, eindex ) = nodes;
    ws ( :, eindex ) = weight ( index, : );
end

% Builds the sparse matrix.
weights = sparse ( es, ns, ws, nele, nsol );
