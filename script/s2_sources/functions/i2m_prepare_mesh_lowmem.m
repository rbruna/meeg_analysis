function bnd = i2m_prepare_mesh ( cfg, mri )

% Makes sure that cfg.tissue is a cell.
cfg.tissue = cellstr ( cfg.tissue );

% Checks that all the tissues exist.
if ~all ( ismember ( cfg.tissue, fieldnames ( mri ) ) )
    error ( 'Tissues not present in data.\n' );
end

% Check the MRI transformation.
if ~isfield ( mri, 'transform' )
    mri.transform = eye (4);
end

% Initializes the output.
bnd = struct ( 'pnt', {}, 'tri', {} );
bnd ( numel ( cfg.tissue ) ).tri = [];

% Adds the iso2mesh toolbox to the path.
ft_hastoolbox ( 'iso2mesh', 1 );

% Goes through each tissue.
for tindex = 1: numel ( cfg.tissue )
    
    % Gets the tissue label.
    tissue   = cfg.tissue { tindex };
    
%     opt = [];
%     opt.radbound = 3;
%     opt.maxnode  = 3000;
%     opt.maxsurf  = 1;
%     opt.keepratio = 1/100;
%     
%     [ node, face ] = v2s ( mri.( tissue ), 1, opt, 'simplify' );
    
    % Generates a high density mesh form the binary segmentation.
    [ node, face ] = binsurface ( mri.( tissue ) );
    
    % Fixes the surface and fills holes.
    [ node, face ] = meshcheckrepair ( node, face );
    
    % Resamples the mesh to one hundreth.
    [ node, face ] = meshresample ( node, face, 1 / 100 );
    
    % Removes self intersections.
    [ node, face ] = meshcheckrepair ( node, face, 'meshfix' );
    
    % Applies the MRI transformation.
    node = ft_warp_apply ( mri.transform, node );
    
    % Stores the mesh.
    bnd ( tindex ).pnt = node;
    bnd ( tindex ).tri = face;
end

% Copies the geometrical units from the MRI.
if isfield ( mri, 'unit' )
    [ bnd.unit ] = deal ( mri.unit );
end
