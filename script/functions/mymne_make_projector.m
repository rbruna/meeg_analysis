function proj = mymne_make_projector ( projinfo, channel, badchan )

% Gets the number of channels and projectors.
nchan   = numel ( channel );
nproj   = numel ( projinfo );

% Initializes the projector to the identity matrix.
proj    = eye ( nchan );

% If no projectors, exits.
if nproj == 0, return, end

% Initializes the projectors' cell-array.
vectors = cell ( nproj, 1 );

% Goes through each projector.
for pindex = 1: nproj
    
    % Gets the list of affected channels.
    chindex = my_matchstr ( channel, projinfo ( pindex ).data.col_names );
    
    % Gets only the channels present in the data.
    chvalid = isfinite ( chindex );
    
    % Gets the vector in the desired form.
    vector  = zeros ( nchan, projinfo ( pindex ).data.nrow );
    vector ( chindex ( chvalid ), : ) = projinfo ( pindex ).data.data ( chvalid );
    
    % Stores the vector.
    vectors { pindex } = vector;
end

% Concatenates all the vectors in a matrix.
vectors = cat ( 2, vectors {:} );

% Removes the bad channels and the empty projectors.
vectors ( ismember ( channel, badchan ), : ) = 0;
vectors = vectors ( :, any ( vectors ~= 0 ) );

% Normalizes the projectors.
vectors = vectors / diag ( sqrt ( diag ( vectors' * vectors ) ) );


% If no valid projectors, exits.
if size ( vectors, 2 ) == 0, return, end

% Removes the linearly dependent projectors.
[ u, s, ~ ] = svd ( vectors, 'econ' );
s       = diag ( s );
u       = u ( :, s / max ( s ) > 1e-2 );

% Gets the projector itself.
proj    = proj - u * u';
