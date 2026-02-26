function asegmask = my_getBrainFS ( mri )

% Gets the gray matter.
asegmask   = mri.aseg > 0;

% Fixes the mask.
asegmask   = mymop_dilateO2 ( asegmask );
asegmask   = imfill ( asegmask, 'holes' );
asegmask   = mymop_erodeO2  ( asegmask );
