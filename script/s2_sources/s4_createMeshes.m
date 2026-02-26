clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.patt = '*.mat';

% Whether to sanitize (and reslize to 1mm3) prior to mesh generation.
config.sanitize  = true;
config.reslice   = true;

% Origin of the masks to use. Can be SPM, pseudoCT, CT or FT (FieldTrip).
config.mask2use  = 'SPM';

% Methods to use to construct the mesh:
% * 'mni-ss'    - Single shell based in the MNI template.
% * 'ss'        - Single shell based in the subject's brain.
% * 'bem3'      - 3-layer BEM model using iso2mesh.
% * 'bem3ft'    - 3-layer BEM model using FieldTrip's implementation.
% * 'bem3NFT'   - 3-layer BEM model using NFT.
config.mesh      = 'bem3';
config.vertices  = [ 1500 1000 1000 ];

% Action when the anatomy has already been processed.
config.overwrite = false;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'openmeeg', 1, 1 );
ft_hastoolbox ( 'freesurfer', 1, 1 );


% Gets the files list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the MRI.
    mridata          = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject' );
    
    fileinfo         = whos ( '-file', sprintf ( '%s%s', config.path.mri, files ( findex ).name ) );
    if ismember ( 'mesh', { fileinfo.name } ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject %s (already calculated).\n', mridata.subject );
        continue
    end
    
    
    fprintf ( 1, 'Working on subject %s.\n', mridata.subject );
    
    % Loads the MRI data and extracts the masks.
    mridata          = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri', 'landmark', 'transform' );
    mri              = mridata.mri;
    
    % Unpacks the MRI.
    mri              = my_unpackmri ( mri );
    
    % Gets the indexes to the masks to use.
    brainpos         = strcmpi ( mri.masklabel, sprintf ( 'brain %s', config.mask2use ) );
    skullpos         = strcmpi ( mri.masklabel, sprintf ( 'skull %s', config.mask2use ) );
    scalppos         = strcmpi ( mri.masklabel, 'scalp' );
    
    if ~any ( brainpos ) || ~any ( skullpos )
        fprintf ( 1, '  Not ''%s'' masks available for brain or skull. Ignoring.\n', config.mask2use );
        continue
    end
    
    % Creates a dummy MRI containing only the segmentation masks.
    dummy            = [];
    dummy.dim        = mri.dim;
    dummy.anatomy    = mri.anatomy;
    dummy.transform  = mri.transform;
    dummy.unit       = mri.unit;
    dummy.coordsys   = mri.coordsys;
    dummy.brain      = mri.mask ( :, :, :, brainpos );
    dummy.skull      = mri.mask ( :, :, :, skullpos );
    dummy.scalp      = mri.mask ( :, :, :, scalppos );
    
    % Converts the MRI to millimeters, if required.
    dummy            = ft_convert_units ( dummy, 'mm' );
    
    
    % Sanitizes the binary masks, if required.
    if config.sanitize
        
        % Checks whether the voxels are square.
        if abs ( abs ( det ( dummy.transform ) ) - 1 ) > 1e-3 || any ( abs ( sum ( dummy.transform ( 1: 3, 1: 3 ) .^ 2 ) - 1 ) > 1e-3 )
            
            % Reslices the MRI to isotropic 1mm3 voxels, if requested.
            if config.reslice
                
                fprintf ( 1, '  Reslicing the anatomical masks.\n' );
                
                % Converts the MRI to AC-PC coordinates.
                dummy.transform  = mridata.transform.vox2acpc;
                dummy.coordsys   = 'acpc';
                
                % Converts the MRI to millimeters, if required.
                dummy            = ft_convert_units ( dummy, 'mm' );
                
                % Gets the bounding box (corners) of the MRI.
                bbox             = mymri_bbox ( dummy );
                
                % Gets the spatial span of the MRI volume.
                range            = cat ( 1, min ( bbox ), max ( bbox ) )';
                
                % Re-slices the MRI to 1x1x1 mm.
                cfg.feedback     = 'none';
                cfg.resolution   = 1;
                cfg.xrange       = range ( 1, : );
                cfg.yrange       = range ( 2, : );
                cfg.zrange       = range ( 3, : );
                
                dummy            = ft_volumereslice ( cfg, dummy );
                
                % Thresholds the masks.
                dummy.brain      = dummy.brain > 0.95;
                dummy.skull      = dummy.skull + dummy.brain > 0.95;
                dummy.scalp      = dummy.scalp + dummy.skull + dummy.brain > 0.95;
                
                % Goes back to the native coordinate system.
                dummy.transform  = ( mridata.transform.vox2nat / mridata.transform.vox2acpc ) * dummy.transform;
                dummy.coordsys   = 'ras';
            else
                warning ( '  The MRI voxels are not isometric 1mm3. Review the results carefully.' )
            end
        end
        
        
        fprintf ( 1, '  Sanitizing the anatomical masks.\n' );
        
        % Padds the volumes with zeros.
        dummy.brain      = mymop_addpad3 ( dummy.brain, 10 );
        dummy.skull      = mymop_addpad3 ( dummy.skull, 10 );
        dummy.scalp      = mymop_addpad3 ( dummy.scalp, 10 );
        
        % Applies a bounding box to the skull and the brain.
        dummy.skull      = dummy.skull & mymop_erodeO2 ( dummy.scalp );
        dummy.brain      = dummy.brain & mymop_erodeO2 ( mymop_erodeO2 ( dummy.scalp ) );
        
        % Sanitizes the surface meshes.
        dummy.brain      = mymop_erodeO2 ( mymop_dilateO2 ( dummy.brain ) );
        dummy.skull      = mymop_erodeO2 ( mymop_dilateO2 ( dummy.skull ) );
        dummy.scalp      = mymop_erodeO2 ( mymop_dilateO2 ( dummy.scalp ) );
        
        % Makes sure that the meshes are non-intersecting.
%         dummy.skull      = dummy.skull | mymop_dilate26 ( dummy.brain );
%         dummy.scalp      = dummy.scalp | mymop_dilate26 ( dummy.skull );
        dummy.skull      = dummy.skull | mymop_dilate26 ( mymop_dilateO2 ( dummy.brain ) );
        dummy.scalp      = dummy.scalp | mymop_dilate26 ( mymop_dilateO2 ( dummy.skull ) );
        
        % Removes the padding.
        dummy.brain      = mymop_rmpad3 ( dummy.brain, 10 );
        dummy.skull      = mymop_rmpad3 ( dummy.skull, 10 );
        dummy.scalp      = mymop_rmpad3 ( dummy.scalp, 10 );
    end

    
    fprintf ( 1, '  Creating a high resolution mesh surface for the scalp.\n' );
    
    % Initializes the scalp structure.
    scalp            = [];
    scalp.type       = 'scalp';
    scalp.tissue     = { 'scalp' };
    scalp.fid        = [];
    scalp.pos        = [];
    scalp.nrm        = [];
    scalp.bnd        = [];
    
    % Generates the mesh.
    cfg              = [];
    cfg.tissue       = { 'scalp' };
    cfg.numvertices  = 10000;
    cfg.offset       = 2;
    
    scalp.bnd        = i2m_prepare_mesh ( cfg, dummy );
    
    % Adds the Neuromag fiducials in real-world coordinates.
    scalp.fid.pos    = cat ( 1, mridata.landmark.nm.lpa, mridata.landmark.nm.nas, mridata.landmark.nm.rpa );
    scalp.fid.label  = { 'LPA'; 'Nasion'; 'RPA' };
    scalp.fid        = ft_transform_geometry ( mri.transform, scalp.fid );
    
    % Adds the scalp-based headshape points and its normals.
    scalp.pos        = scalp.bnd.pos;
    scalp.nrm        = ft_normals ( scalp.bnd.pos, scalp.bnd.tri );
    
    
    fprintf ( 1, '  Creating mesh surfaces for the defined masks.\n' );
    
    % Transforming the MNI head model to subject space.
    if strcmp ( 'mni-ss', config.mesh )
        
        mesh             = [];
        mesh.type        = 'mni-singleshell';
        mesh.tissue      = { 'brain' };
        mesh.bnd         = template.volume.bnd;
        
        % Transforms the mesh to subject-space.
        mesh.bnd         = ft_convert_units ( mesh.bnd, 'mm' );
        mesh.bnd         = ft_transform_geometry ( mridata.mri.mni2sub.trans, mesh.bnd );
    end
    
    % Generates the head model using Nolte's approach.
    if strcmp ( 'ss', config.mesh )
        
        % Initializes the mesh structure.
        mesh             = [];
        mesh.type        = 'singleshell';
        mesh.tissue      = { 'brain' };
        
        % Generates the brain mesh.
        cfg              = [];
        cfg.tissue       = { 'brain' };
        cfg.numvertices  = config.vertices (1);
        cfg.offset       = 2;
        
        mesh.bnd         = i2m_prepare_mesh ( cfg, dummy );
        
        % Adds the scalp mesh for visualization.
        mesh.tissue      = cat ( 2, mesh.tissue, { 'scalp' } );
        mesh.bnd         = cat ( 2, mesh.bnd, scalp.bnd );
    end
    
    % Generates the three meshes head model using iso2mesh.
    if strcmp ( 'bem3', config.mesh )
        
        % Initializes the mesh structure.
        mesh             = [];
        mesh.type        = 'bem3';
        mesh.tissue      = { 'brain', 'skull', 'scalp' };
        
        % Generates the meshes.
        cfg              = [];
        cfg.tissue       = { 'brain', 'skull', 'scalp' };
        cfg.numvertices  = config.vertices;
        cfg.offset       = 2;
        
        mesh.bnd         = i2m_prepare_mesh ( cfg, dummy );
    end
    
    % Generates the three meshes head model using FieldTrip.
    if strcmp ( 'bem3ft', config.mesh )
        
        % Initializes the mesh structure.
        mesh             = [];
        mesh.type        = 'bem3ft';
        mesh.tissue      = { 'brain', 'skull', 'scalp' };
        
        % Generates the meshes.
        cfg              = [];
        cfg.method       = 'iso2mesh';
        cfg.tissue       = { 'brain', 'skull', 'scalp' };
        cfg.numvertices  = config.vertices;
        
        mesh.bnd         = ft_prepare_mesh ( cfg, dummy );
    end
    
    % Generates the three meshes head model using NFT.
    if strcmp ( 'bem3NFT', config.mesh )
        
        % Initializes the mesh structure.
        mesh             = [];
        mesh.type        = 'bem3NFT';
        mesh.tissue      = { 'brain', 'skull', 'scalp' };
        
        % Generates the meshes.
        cfg              = [];
        cfg.tissue       = { 'brain', 'skull', 'scalp' };
        cfg.numvertices  = config.vertices;
        
        mesh.bnd         = NFT_prepare_mesh ( cfg, dummy );
    end
    
    % Corrects intersecting meshes.
    mesh.bnd         = ft_convert_units ( mesh.bnd, 'mm' );
    mesh.bnd         = NFT_mfc ( mesh.bnd );
    mesh.bnd         = ft_convert_units ( mesh.bnd, 'm' );
    
    
    fprintf ( 1, '  Saving the generated surfaces.\n' );
    
    % Updates the anatomy data with the surface meshes.
    mridata.scalp    = scalp;
    mridata.mesh     = mesh;
    
    % Saves the anatomy data.
    save ( '-v6', sprintf ( '%s%s_3DT1', config.path.mri, mridata.subject ), '-struct', 'mridata' );
end
