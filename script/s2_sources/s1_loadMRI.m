clc
clear
close all

% Defines the location of the files.
config.path.in   = '../../data/anatomy/T1/';
config.path.mri  = '../../data/anatomy/MAT/';
config.path.patt = '*.nii.gz';

% Action when the anatomy has already been processed.
config.overwrite = false;


% Creates and output folder, if needed.
if ~exist ( config.path.mri, 'dir' ), mkdir ( config.path.mri ); end


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'freesurfer', 1, 1 );


% Gets the file list.
files = dir ( sprintf ( '%s%s', config.path.in, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Gets the MRI filename.
    mrifile            = files ( findex ).name;
    [ ~, subject ]     = fileparts ( mrifile );
    [ ~, subject ]     = fileparts ( subject );
    subject            = strrep ( subject, '_3DT1', '' );
    
    if exist ( sprintf ( '%s%s_3DT1.mat', config.path.mri, subject ), 'file' ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject %s (already loaded).\n', subject );
        continue
    end
    
    fprintf ( 1, 'Loading NIfTI file for subject %s.\n', subject );
    
    % Gets the MRI file.
    mri                = my_read_mri ( sprintf ( '%s%s', config.path.in, mrifile ) );
    mri.coordsys       = 'ras';
    
    % Stores the original transformation.
    transform.unit     = mri.unit;
    transform.vox2nat  = mri.transform;
    
    
    % Asks for the MRI fiducials.
    cfg                = [];
    cfg.coordsys       = 'neuromag';
    
    dummy              = ft_volumerealign ( cfg, mri );
    landmark.nm        = dummy.cfg.fiducial;
    transform.vox2nm   = dummy.transform;
    drawnow
    
    
    % Asks for the SPM landmarks.
    cfg                = [];
    cfg.coordsys       = 'acpc';
    
    dummy              = ft_volumerealign ( cfg, mri );
    landmark.acpc      = dummy.cfg.fiducial;
    transform.vox2acpc = dummy.transform;
    drawnow
    
    
    % Transforms the data to uint16 to save memory.
    mri.anatomy        = uint16 ( mri.anatomy );
    
    
    fprintf ( '  Saving the anatomy file.\n' );
    
    % Saves the MRI data.
    mridata            = [];
    mridata.subject    = subject;
    mridata.landmark   = landmark;
    mridata.transform  = transform;
    mridata.mri        = mri;
    
    save ( '-v6', sprintf ( '%s%s_3DT1', config.path.mri, subject ), '-struct', 'mridata' )
end
