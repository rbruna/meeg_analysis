function headmodel = myom_untrimmat ( headmodel )

% Trims the sources-to-head matrix or the system matrix to include only the
% nodes in the scalp (outermost) mesh.


% Gets the dimensions of the surface meshes.
npos      = arrayfun ( @(bnd) size ( bnd.pos, 1 ), headmodel.bnd );
ntri      = arrayfun ( @(bnd) size ( bnd.tri, 1 ), headmodel.bnd );

% Gets the total numel of elements in the head matrix.
nelem     = sum ( npos ) + sum ( ntri ( 1: end - 1 ) );

% Gets the position of the scalp nodes.
% This position depends on the version of OpenMEEG used.
if strncmp ( headmodel.version, '2.2', 3 )
    offset    = sum ( npos ( 1: end - 1 ) ) + sum ( ntri ( 1: end - 1 ) );
elseif strncmp ( headmodel.version, '2.4', 3 )
    offset    = sum ( npos ( 1: end - 1 ) );
else
    error ( 'Unknown version of OpenMEEG' );
end
sindex    = offset + ( 1: npos ( end ) );


% Modifies the inverse head matrix, if present.
if isfield ( headmodel, 'tihm' )
    
    if myom_verbosity, fprintf ( 1, 'Expanding the head model matrix.\n' ); end
    
    % Generates an empty inverse head matrix.
    headmodel.ihm    = zeros ( nelem, nelem );
    
    % Fills only the entries related to the scalp nodes.
    headmodel.ihm ( sindex, : ) = headmodel.tihm;
    
    % Removes the trimmed version.
    headmodel        = rmfield ( headmodel, 'ihm' );
end

% Modifies the hm\dsm matrix, if present.
if isfield ( headmodel, 'thm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Expanding the potential matrix.\n' ); end
    
    % Gets the number of source positions.
    nsrc             = size ( headmodel.thm_dsm, 2 );
    
    % Generates an empty inverse hm\dsm matrix.
    headmodel.hm_dsm = zeros ( nelem, nsrc );
    
    % Fills only the entries related to the scalp nodes.
    headmodel.hm_dsm ( sindex, : ) = headmodel.thm_dsm;
    
    % Removes the trimmed version.
    headmodel        = rmfield ( headmodel, 'thm_dsm' );
end
