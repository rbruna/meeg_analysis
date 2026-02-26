function skullmask = my_getSkullFT ( mri )

% Gets the brain mask.
brainpos   = strcmpi ( mri.masklabel, 'brain FT' );
brainmask  = mri.mask ( :, :, :, brainpos );

% Creates the skull as a dilation of 6 voxels outside the brain.
skullmask  = imdilate ( brainmask, strel_bol (6) );
