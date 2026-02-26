clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.patt = '*.mat';

% Action when the anatomy has already been processed.
config.overwrite = false;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );


% Gets the file list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the MRI.
    mridata       = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'transform' );
    
    if ~isfield ( mridata.transform, 'mni2nat' )
        fprintf ( 1, 'Ignoring subject %s (No yet segmented).\n', mridata.subject );
        continue
    end
    
    fileinfo      = whos ( '-file', sprintf ( '%s%s', config.path.mri, files ( findex ).name ) );
    if ismember ( 'mesh', { fileinfo.name } ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject %s. (Surfaces already generated)\n', mridata.subject );
        continue
    end
    
    
    fprintf ( 1, 'Working on subject %s.\n', mridata.subject );
    
    % Loads the MRI.
    mridata       = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri', 'landmark', 'transform' );
    mri           = mridata.mri;
    
    % Unpacks the MRI.
    mri           = my_unpackmri ( mri );
    
    
    % Creates the SPM/FT masks.
    fprintf ( 1, '  Creating binary masks for each tissue.\n' );
    
    % Initializes the mask fields, if required.
    if ~isfield ( mri, 'masklabel' )
        mri.masklabel = {};
    end
    
    % Generates the scalp mask using SPM.
    if ismember ( 'Scalp', mri.masklabel ) && ~config.overwrite
        fprintf ( 1, '    Ignoring ''scalp'' (already calculated).\n' );
    else
        fprintf ( 1, '    Generating ''scalp'' mask.\n' );
        
        % Gets the position of the mask or adds it.
        mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Scalp' ), 'stable' );
        maskpos       = find ( strcmpi ( mri.masklabel, 'Scalp' ) );
        
        % Generates the mask and stores it.
        mri.mask ( :, :, :, maskpos ) = my_getScalp ( mri );
    end
    
    % Generates the brain mask using SPM.
    if isfield ( mri, 'gray' ) && isfield ( mri, 'white' ) && isfield ( mri, 'csf' )
        if ismember ( 'Brain SPM', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''brain'' mask from the SPM segmentation (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''brain'' mask from the SPM segmentation.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Brain SPM' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Brain SPM' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getBrainSPM ( mri );
        end
    end
    
    % Generates the skull mask using SPM's bone segmentation.
    if isfield ( mri, 'bone' )
        if ismember ( 'Skull SPM', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''skull'' mask from the SPM segmentation (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''skull'' mask from the SPM segmentation.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Skull SPM' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Skull SPM' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getSkullSPM ( mri );
        end
    end
    
    % Generates the brain and skull masks using FieldTrip.
    if isfield ( mri, 'gray' ) && isfield ( mri, 'white' ) && isfield ( mri, 'csf' )
        if ismember ( 'Brain FT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''brain'' mask using FieldTrip method (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''brain'' mask using FieldTrip method.\n' );
            
            % Gets the SPM brain mask calculated before.
            maskpos       = strcmpi ( mri.masklabel, 'Brain SPM' );
            brainmask     = mri.mask ( :, :, :, maskpos );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Brain FT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Brain FT' ) );
            
            % Stores the mask with a new name.
            mri.mask ( :, :, :, maskpos ) = brainmask;
        end
        if ismember ( 'Skull FT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''skull'' mask using FieldTrip method (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''skull'' mask using FieldTrip method.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Skull FT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Skull FT' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getSkullFT ( mri );
        end
    end
    
    % Generates the skull mask using the pseudo-CT image.
    if isfield ( mri, 'pct' )
        if ismember ( 'Skull pseudoCT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''skull'' mask from the pseudo-CT image (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''skull'' mask from the pseudo-CT image.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Skull pseudoCT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Skull pseudoCT' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getSkullpCT ( mri );
        end
        if ismember ( 'Brain pseudoCT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''brain'' mask from the pseudo-CT image (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''brain'' mask from the pseudo-CT image.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Brain pseudoCT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Brain pseudoCT' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getBrainpCT ( mri );
        end
    end
    
    % Generates the skull mask using the CT image.
    if isfield ( mri, 'ct' )
        if ismember ( 'Skull CT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''skull'' mask from the CT image (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''skull'' mask from the CT image.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Skull CT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Skull CT' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getSkullCT ( mri );
        end
        if ismember ( 'Brain CT', mri.masklabel ) && ~config.overwrite
            fprintf ( 1, '    Ignoring ''brain'' mask from the CT image (already calculated).\n' );
        else
            fprintf ( 1, '    Generating ''brain'' mask from the CT image.\n' );
            
            % Gets the position of the mask or adds it.
            mri.masklabel = unique ( cat ( 1, mri.masklabel, 'Brain CT' ), 'stable' );
            maskpos       = find ( strcmpi ( mri.masklabel, 'Brain CT' ) );
            
            % Generates the mask and stores it.
            mri.mask ( :, :, :, maskpos ) = my_getBrainCT ( mri );
        end
    end
    
    
    fprintf ( 1, '  Saving the anatomy file.\n' );
    
    % Packs the MRI to save space.
    mri           = my_packmri ( mri );
    
    % Updates the anatomy data.
    mridata.mri   = mri;
    
    % Saves the masks.
    save ( '-v6', sprintf ( '%s%s_3DT1', config.path.mri, mridata.subject ), '-struct', 'mridata' )
end
