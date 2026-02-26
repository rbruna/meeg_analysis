function bnd = i2m_prepare_mesh ( cfg, mri )

% Makes sure that cfg.tissue is a cell.
cfg.tissue = cellstr ( cfg.tissue );

% Checks that all the tissues exist.
if ~all ( ismember ( cfg.tissue, fieldnames ( mri ) ) )
    error ( 'Tissues not present in data.\n' );
end

% Adds the iso2mesh toolbox to the path.
ft_hastoolbox ( 'iso2mesh', 1, 1 );


% Checks the MRI transformation.
if ~isfield ( mri, 'transform' )
    mri.transform = eye (4);
end

% Checks if there is a provided offset.
if ~isfield ( cfg, 'offset' )
    cfg.offset = 0;
end

% Fixes the destination number of nodes for each surface.
if isfield ( cfg, 'numvertices' )
    
    % If only one value, repeats it.
    if numel ( cfg.numvertices ) == 1
        cfg.numvertices = repmat ( cfg.numvertices, size ( cfg.tissue ) );
    
    % If incorrect values sets the value to 1000.
    elseif numel ( cfg.numvertices ) ~= numel ( cfg.tissue )
        cfg.numvertices = repmat ( 1000, size ( cfg.tissue ) );
    end
end


% Defines the offset array.
off = repmat ( ' ', 1, 2 * cfg.offset );

% Initializes the output.
bnd = struct ( 'tissue', {}, 'pos', {}, 'tri', {} );
bnd ( numel ( cfg.tissue ) ).tri = [];

% Goes through each tissue.
for tindex = 1: numel ( cfg.tissue )
    
    fprintf ( 1, '%sGenerating a surface mesh for tissue ''%s''.\n', off, cfg.tissue { tindex } );
    
    % Initializes the mesh.
    mesh           = [];
    
    % Gets the tissue label.
    mesh.tissue    = cfg.tissue { tindex };
    
    % Gets the mask and adds a voxel of padding.
    mask           = mri.( mesh.tissue );
    mask           = padarray ( mask, [ 1 1 1 ] );
    
    % Generates a high density mesh form the binary segmentation.
    [ node, face ] = binsurface ( mask );
    node           = node - 1;
    
    % Stores the mesh in FieldTrip format.
    mesh.pos       = node;
    mesh.tri       = face;
    
    
    % Fixes the surface and fills holes.
    mesh           = meshfix ( mesh );
    
    % Subsamples the mesh, if needed.
    mesh           = meshresample ( mesh, cfg.numvertices ( tindex ) );
    
    % Fixes the surface and fills holes.
    mesh           = meshfix ( mesh );
    
    % Applies the MRI transformation.
    mesh           = ft_transform_geometry ( mri.transform, mesh );
    
    % Stores the mesh.
    bnd ( tindex ) = mesh;
end

% Copies the geometrical units from the MRI.
if isfield ( mri, 'unit' )
    [ bnd.unit ] = deal ( mri.unit );
end

function mesh = meshfix ( mesh )

% Determines the base name for the temporal file.
basename       = tempname;

% Saves the mesh as an Object File Format file.
saveoff ( mesh.pos, mesh.tri, sprintf ( '%s.off', basename ) );


% In Windows uses a special version of meshfix.
if ispc
    [ state, out ]  = system ( sprintf ( '"%s\\%s" "%s.off" "%s.off"', fileparts ( mfilename ( 'fullpath' ) ), 'meshfix-win.exe', basename, basename ) );
    
else
    
    % Gets the full path to the executable.
    binpath         = mcpath ( sprintf ( 'meshfix%s', fallbackexeext ( getexeext, 'meshfix' ) ) );
    
    % Updates the permissions to the executable, if required.
    if isunix
        system ( sprintf ( 'chmod +x "%s"', binpath ) );
    end
    
    % Performs the cleaning.
    [ state, out ]  = system ( sprintf ( '"%s" "%s.off" -o "%s" -q -a 0.01', binpath, basename, basename ) );
end
if state, error ( out ); end

% Loads the Object File Format file.
[ node, face ] = readoff ( sprintf ( '%s.off', basename ) );
mesh.pos       = node;
mesh.tri       = face;

% Removes the temporal file.
delete ( sprintf ( '%s.off', basename ) )


function mesh = meshresample ( mesh, nodes )

% Calculates the mesh subsampling ratio.
ratio          = nodes / size ( mesh.pos, 1 );

% If ratio is greater than 1 does nothing.
if ratio > 1, return, end

% Determines the base name for the temporal file.
basename       = tempname;

% Gets the full path to the executable.
binpath        = mcpath ( sprintf ( 'cgalsimp2%s', fallbackexeext ( getexeext, 'cgalsimp2' ) ) );

% Updates the permissions to the executable, if required.
if isunix
    system ( sprintf ( 'chmod +x "%s"', binpath ) );
end

% Saves the mesh as an Object File Format file.
saveoff ( mesh.pos, mesh.tri, sprintf ( '%s.off', basename ) );

% Performs the cleaning.
[ state, out ] = system ( sprintf ( '"%s" "%s.off" %f "%s.off"', binpath, basename, ratio, basename ) );
if state, error ( out ); end

% Loads the Object File Format file.
[ node, face ] = readoff ( sprintf ( '%s.off', basename ) );
mesh.pos       = node;
mesh.tri       = face;

% Removes the temporal file.
delete ( sprintf ( '%s.off', basename ) )
