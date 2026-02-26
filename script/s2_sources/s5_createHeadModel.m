clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.head = '../../data/headmodel/';
config.path.patt = '*.mat';

% Defines the head model. Can be 'bem3', 'ss' (single shell) or 'auto'.
config.model     = 'bem3';

% Defines the template sources model to use.
config.sources   = '../../template/grid/CTB-10mm.mat';

% Action when the task have already been processed.
config.overwrite = false;


% Creates the output folder, if required.
if ~exist ( config.path.head, 'dir' ), mkdir ( config.path.head ); end


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'openmeeg', 1, 1 );
ft_hastoolbox ( 'freesurfer', 1, 1 );


% Loads the sources template MRI and grid.
srctemp = load ( config.sources );


% Gets the files list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the anatomy.
    mridata           = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mesh' );
    
    if strcmp ( config.model, 'ss' )
        meshtype          = 'singleshell';
    else
        meshtype          = mridata.mesh.type;
    end
    
    if exist ( sprintf ( '%s%s_%s_%s.mat', config.path.head, mridata.subject, meshtype, srctemp.model ), 'file' ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject %s (already calculated).\n', mridata.subject );
        continue
    end
    
    
    fprintf ( 1, 'Working on subject %s.\n', mridata.subject );
    
    % Loads the anatomy and the surface mesh(es).
    mridata           = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri', 'landmark', 'transform', 'mesh', 'scalp' );
    mri               = mridata.mri;
    transform         = mridata.transform;
    mesh              = mridata.mesh;
    
    % Unpacks the MRI.
    mri               = my_unpackmri ( mri );
    
    
    % Sanitizes the surface meshes.
    if strcmp ( config.model, 'bem3' ) && ~strncmp ( mesh.type, 'bem', 3 )
        fprintf ( 1, 'Ignoring subject %s (not valid for three-layer BEM).\n', mridata.subject );
        continue
    end
    
    % Converts the surface into single-shell, if requested.
    if strcmp ( config.model, 'ss' ) && ~strcmp ( mesh.type, 'ss' )
        
        % Gets only the brain surface mesh.
        hit               = strcmp ( mesh.tissue, 'brain' );
        mesh.type         = 'singleshell';
        mesh.tissue       = mesh.tissue ( hit );
        mesh.bnd          = mesh.bnd ( hit );
    end
    
    
    fprintf ( 1, '  Transforming the template (MNI) sources model to subject space.\n' );
    
    % Gets the template (MNI) sources model.
    srcmodel          = srctemp.sourcemodel;
    
    % Stores the original source definition.
    srcmodel.posori  = srcmodel.pos;
    if isfield ( srcmodel, 'nrm' )
        srcmodel.nrmori   = srcmodel.nrm;
    end
    
    % Transforms the sources model to subject's native space.
    srcmodel          = ft_convert_units ( srcmodel, transform.unit );
    srcmodel          = ft_transform_geometry ( transform.mni2nat, srcmodel );
    srcmodel          = ft_convert_units ( srcmodel, 'm' );
    
    
    % Moves the sources inside the brain surface for BEM methods.
    if strncmp ( mesh.type, 'bem', 3 )
        
        fprintf ( 1, '  Moving the sources inside the brain surface.\n' );
        
        % Creates a grid containing only the sources inside the brain.
        tmpgrid           = srcmodel;
        tmpgrid.pos       = tmpgrid.pos ( tmpgrid.inside, : );
        tmpgrid.inside    = true ( size ( tmpgrid.pos, 1 ), 1 );
        
        % Moves all the sources of the grid inside the brain surface.
        cfg               = [];
        cfg.sourcemodel   = tmpgrid;
        cfg.headmodel     = mesh;
        cfg.headmodel.type = 'openmeeg';
        cfg.moveinward    = 0.001;
        cfg.inwardshift   = 0;
        
        tmpgrid           = ft_prepare_sourcemodel ( cfg );
        
        % Replaces the position of the sources inside the brain.
        srcmodel.pos ( srcmodel.inside, : ) = tmpgrid.pos;
    end
    
    
    fprintf ( 1, '  Saving the sources model.\n' );
    
    % Creates the head model.
    headdata           = [];
    headdata.subject   = mridata.subject;
    headdata.model     = mesh.type;
    headdata.sources   = srctemp.model;
    headdata.mri       = mridata.mri;
    headdata.landmark  = mridata.landmark;
    headdata.transform = mridata.transform;
    headdata.mesh      = mesh;
    headdata.scalp     = mridata.scalp;
    headdata.grid      = srcmodel;
    
    % Saves the head model.
    save ( '-v6', sprintf ( '%s%s_%s_%s.mat', config.path.head, headdata.subject, headdata.model, headdata.sources ), '-struct', 'headdata' );
end
