clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.patt = '*.mat';

% Action when the anatomy has already been processed.
config.overwrite = false;

% Version of SPM to use ('spm8' or 'spm12').
config.spmver    = 'spm12';


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/spm12_functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
% ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'freesurfer', 1, 1 );


% Gets the file list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the MRI.
    mridata            = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'transform' );
    
    % Checks if the MRI has already being segmented.
    if isfield ( mridata.transform, 'mni2nat' ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject %s (Already calculated).\n', mridata.subject );
        continue
    end
    
    
    fprintf ( 1, 'Working on subject %s.\n', mridata.subject );
    
    % Loads the MRI.
    mridata            = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri', 'landmark', 'transform' );
    
    % Gets the data.
    mri                = mridata.mri;
    landmark           = mridata.landmark;
    transform          = mridata.transform;
    
    % Unpacks the MRI.
    mri                = my_unpackmri ( mri );
    
    
    fprintf ( 1, '  Creating a tissue probability map from the MRI.\n' );
    
    % Generates a dummy MRI with only the anatomy.
    dummy              = [];
    dummy.hdr          = mri.hdr;
    dummy.dim          = mri.dim;
    dummy.anatomy      = mri.anatomy;
    dummy.transform    = mri.transform;
    dummy.coordsys     = mri.coordsys;
    dummy.unit         = mri.unit;
    
    % Transforms the MRI to AC-PC coordinates.
    dummy.transform    = transform.vox2acpc;
    
    
    % Performs the brain segmentation using SPM8.
    if strcmp ( config.spmver, 'spm8' )
        
        % Performs the segmentation.
        cfg                = [];
        cfg.spmversion     = 'spm8';
        cfg.output         = 'tpm';
        cfg.template       = sprintf ( '%s/external/spm8/templates/T1.nii', fileparts ( which ( 'ft_defaults' ) ) );
        cfg.downsample     = 1;
        
        dummy              = ft_volumesegment ( cfg, dummy );
        
        % Adds the TPM to the original MRI.
        mri.gray           = dummy.gray;
        mri.white          = dummy.white;
        mri.csf            = dummy.csf;
    
    % Performs the brain segmentation using SPM12.
    else
        
        % Performs the segmentation.
        mri                = spm12_segment ( dummy );
        
        % Gets the MNI-to-subject transformation.
        transform.mni2nat  = ( transform.vox2nat / transform.vox2acpc ) * mri.mni2sub.trans;
        transform.mni2acpc = mri.mni2sub;
    end
    
    % Restores the original voxel-to-native transformation.
    mri.transform      = transform.vox2nat;
    
    
    fprintf ( 1, '  Saving the anatomy file.\n' );
    
    % Packs the MRI to save space.
    mri                = my_packmri ( mri );
    
    % Updates the anatomy data with the segmented anatomy.
    mridata.mri        = mri;
    mridata.transform  = transform;
    
    % Saves the anatomy data.
    save ( '-v6', sprintf ( '%s%s_3DT1', config.path.mri, mridata.subject ), '-struct', 'mridata' )
end
