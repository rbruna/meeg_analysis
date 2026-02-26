function skullmask = BS_segmentSkull ( mridata, aseg )
% Uses BrainSuite to segment the subject's skull.

% Generates a temporal name for the intermediate files.
basename = tempname;


% Saves the original MRI.
mri       = mridata.anatomy;
mri       = double ( mri );

ft_write_mri ( sprintf ( '%s_mri.nii', basename ), mri, 'dataformat', 'nifti' );


fprintf ( 1, 'Creating the brain mask.\n' );

% Generates a brain mask from the FreeSurfer segmentation.
brainmask     = aseg.anatomy ~= 0;
brainmask     = imclose ( brainmask, ones ( 5,5,5 ) );
brainmask     = imfill  ( brainmask, 'holes' );
brainmask     = 255 * double ( brainmask );

ft_write_mri ( sprintf ( '%s_brainmask.nii', basename ), brainmask, 'dataformat', 'nifti' );


fprintf ( 1, 'Segmentating the skull.\n' );

% Performs the skull segmentation and filters the resulting mask.
system ( sprintf ( './functions/skullfinder -i %s_mri.nii -m %s_brainmask.nii -o %s_skull.nii', basename, basename, basename ) );
% system ( sprintf ( './functions/scrubmask -i %s_skull.nii -o %s_skull.nii', basename, basename ) );


fprintf ( 1, 'Fixing errors in the skull mask.\n' );

% Loads the skull (and inner tissues) mask.
skull     = ft_read_mri ( sprintf ( '%s_skull.nii', basename ) );
skullmask = skull.anatomy >= 17;

% Fix the segmented skull to include the whole brain and avoid the scalp.
brainmask = mridata.brain;
scalpmask = mridata.scalp;

brainmask = imdilate ( brainmask, ones ( 5, 5, 5 ) );
scalpmask = imerode  ( scalpmask, ones ( 5, 5, 5 ) );

skullmask = skullmask | brainmask;
skullmask = skullmask & scalpmask;

% Performs a morphological closing to fix holes and imperfections.
skullmask = imclose ( skullmask, ones ( 15, 15, 15 ) );

skullmask = skullmask | brainmask;
skullmask = skullmask & scalpmask;

% Removes the temporal files.
delete ( sprintf ( '%s*', basename ) );
