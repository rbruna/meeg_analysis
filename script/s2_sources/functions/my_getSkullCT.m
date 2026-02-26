function skullmask = my_getSkullCT ( mri )

% Gets a skull estimation from the pseudo-CT.

% Gets the scalp mask.
scalppos   = strcmpi ( mri.masklabel, 'scalp' );
scalpmask  = mri.mask ( :, :, :, scalppos );

% Gets a estimation of the brain.
brainmask  = mri.white + mri.gray + mri.csf > .5;


% Defines the thresholds for the fisrt and second passes.
threshold1 = 200;
threshold2 = 100;

% Gets the skull.
skullmask  = mri.ct > threshold1;

% Removes the points outside the scalp.
skullmask  = skullmask .* single ( scalpmask );

% Forces the minimum skull thickness.
skullmask  = skullmask | mymop_dilate26 ( mymop_dilate26 ( brainmask ) );

% Gets the biggest connected element.
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = skullmask == mode ( skullmask ( skullmask ~= 0 ) );

% Fixes the skull.
skullmask  = mymop_dilateO2 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erodeO2  ( skullmask );


% Goes back to the original image.
skullmask  = skullmask & mri.ct > threshold2;

% Forces the minimum skull thickness.
skullmask  = skullmask | mymop_dilate26 ( mymop_dilate26 ( brainmask ) );

% Keeps only the biggest connected element.
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = ( skullmask == mode ( skullmask ( skullmask ~= 0 ) ) );

% Fixes the skull.
skullmask  = mymop_dilate26 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erode26  ( skullmask );
