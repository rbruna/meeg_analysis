function skullmask = my_getSkullSPM ( mri )

% Gets a skull estimation from SPM segmentation.

% Gets the scalp mask.
scalppos   = strcmpi ( mri.masklabel, 'scalp' );
scalpmask  = mri.mask ( :, :, :, scalppos );

% Gets a estimation of the brain.
brainmask  = mri.white + mri.gray + mri.csf > .5;


% % Identifies the points bellow z = -70 in MNI.
% point1     = mri.transform \ mri.mni2sub.trans * [   0   0 -70   1 ]';
% point2     = mri.transform \ mri.mni2sub.trans * [   0  50 -70   1 ]';
% point3     = mri.transform \ mri.mni2sub.trans * [  50   0 -70   1 ]';
% point4     = mri.transform \ mri.mni2sub.trans * [   0   0 -80   1 ]';
% plane      = cross ( point1 ( 1: 3 ) - point2 ( 1: 3 ), point1 ( 1: 3 ) - point3 ( 1: 3 ) );
% 
% [ d2, d1, d3 ] = meshgrid ( 1: mri.dim (2), 1: mri.dim (1), 1: mri.dim (3) );
% 
% dots       = ( point1 (1) - d1 ) * plane (1) + ( point1 (2) - d2 ) * plane (2) + ( point1 (3) - d3 ) * plane (3);
% 
% spmmask    = sign ( dots ) ~= sign ( dot ( point1 ( 1: 3 ) - point4 ( 1: 3 ), plane ) );
spmmask    = true ( size ( mri.bone ) );


% Defines the thresholds for the fisrt and second passes.
threshold1 = .5;
threshold2 = .5;

% Gets the skull.
skullmask  = spmmask & mri.bone > threshold1;

% Removes the points outside the scalp.
skullmask  = skullmask .* single ( scalpmask );

% Forces the minimum skull thickness.
skullmask  = skullmask | mymop_dilate26 ( mymop_dilate26 ( brainmask ) );

% Fixes the skull.
skullmask  = mymop_dilate26 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erode26  ( skullmask );

% Gets the biggest connected element.
skullmask  = mymop_erode26  ( skullmask );
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = skullmask == mode ( skullmask ( skullmask ~= 0 ) );
skullmask  = mymop_dilate26 ( skullmask );

% Dilates the image.
skullmask  = mymop_dilateO2 ( skullmask );


% Goes back to the original image.
skullmask  = spmmask & skullmask & mri.bone > threshold2;

% Forces the minimum skull thickness.
skullmask  = skullmask | mymop_dilate26 ( mymop_dilate26 ( brainmask ) );

% Keeps only the biggest connected element.
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = ( skullmask == mode ( skullmask ( skullmask ~= 0 ) ) );

% Fixes the skull.
skullmask  = mymop_dilate26 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erode26  ( skullmask );
