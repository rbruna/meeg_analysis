function headmodel = myom_trimmat ( headmodel )

% Trims the sources-to-head matrix or the system matrix to include only the
% nodes in the scalp (outermost) mesh.


% Gets the dimensions of the surface meshes.
npos      = arrayfun ( @(bnd) size ( bnd.pos, 1 ), headmodel.bnd );
ntri      = arrayfun ( @(bnd) size ( bnd.tri, 1 ), headmodel.bnd );

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
if isfield ( headmodel, 'ihm' )
    
    if myom_verbosity, fprintf ( 1, 'Trimming the head model matrix.\n' ); end
    
    % Keeps only the system matrix related to the scalp nodes.
    headmodel.tihm    = headmodel.ihm ( sindex, : );
    
    % Removes the original inverse head matrix.
    headmodel         = rmfield ( headmodel, 'tihm' );
end

% Modifies the hm\dsm matrix, if present.
if isfield ( headmodel, 'hm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Trimming the potential matrix.\n' ); end
    
    % Keeps only the potential related to the scalp nodes.
    headmodel.thm_dsm = headmodel.hm_dsm ( sindex, : );
    
    % Removes the original hm/dsm matrix.
    headmodel         = rmfield ( headmodel, 'hm_dsm' );
end

% Modifies the head to electrodes matrix, if present.
if isfield ( headmodel, 'h2em' )
    
    if myom_verbosity, fprintf ( 1, 'Trimming the electrodes matrix.\n' ); end
    
    % Keeps only the potential related to the scalp nodes.
    headmodel.th2em   = headmodel.h2em ( :, sindex );
    
    % Removes the original electrodes matrix.
    headmodel         = rmfield ( headmodel, 'h2em' );
end

% Adds the scalp boundary, if required.
if isfield ( headmodel, 'tihm' ) || isfield ( headmodel, 'thm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Getting the scalp boundary.\n' ); end
    
    % Gets the outermost boundary.
    headmodel.scalp   = headmodel.bnd ( end );
    
end
