function bnd = NFT_prepare_mesh ( cfg, mri )

% Makes sure that cfg.tissue is a cell.
cfg.tissue = cellstr ( cfg.tissue );

% Checks that all the tissues exist.
if ~all ( ismember ( cfg.tissue, fieldnames ( mri ) ) )
    error ( 'Tissues not present in data.\n' );
end

% Checks the number of vertices option.
if ~isfield ( cfg, 'numvertex' )
    cfg.numvertex = 1000 * ones ( size ( cfg.tissue ) );
end

% Check the MRI transformation.
if ~isfield ( mri, 'transform' )
    mri.transform = eye (4);
end

% Initializes the output.
bnd = struct ( 'pnt', {}, 'tri', {} );
bnd ( numel ( cfg.tissue ) ).tri = [];

% Goes through each tissue.
for tindex = 1: numel ( cfg.tissue )
    
    % Gets the tissue label.
    tissue   = cfg.tissue { tindex };
    
    % Generates a temporal file name.
    basename = tempname;
    rawname  = sprintf ( '%s.raw', basename );
    ascname  = sprintf ( '%s.asc', basename );
    
    % Saves the segmentation in 8 bit format.
    fid      = fopen ( rawname, 'w' );
    fwrite   ( fid, 2 * mri.( tissue ), 'uint8' );
    fclose   ( fid );
    
    % Generates the mesh using 'asc'.
    system ( sprintf ( '"./NFT-2.3/bin/asc1.64" -t 1 -dr1 "%s" %i %i %i -f "%s" -ot -n-', rawname, size ( mri.( tissue ) ), ascname ) );
    
    % Reads the generated mesh.
    bnd ( tindex ) = NFT_read_asc ( ascname );
    
    % Reduces the number of elements of the mesh.
    bnd ( tindex ) = NFT_reduce_mesh ( bnd ( tindex ), cfg.numvertices ( tindex ) * 2 );
    
    % Applies the MRI transformation.
    bnd ( tindex ).pnt = ft_warp_apply ( mri.transform, bnd ( tindex ).pnt );
end

% Copies the geometrical units from the MRI.
if isfield ( mri, 'unit' )
    [ bnd.unit ] = deal ( mri.unit );
end
