function skullmask = my_getSkullBS ( mri )

% Gets a skull estimation using Brain Suite's algorithm.

% % Removes noise in the image.
% fullmri    = MBONLM3D ( double ( fullmri ), 5, 1, 50, 1 );

% Transforms the MRI to uint8.
fullmri    = mri.anatomy;
dummy      = histcounts ( floor ( fullmri (:) ), 0: 65536 );
maxval     = find ( cumsum ( dummy ) > floor ( 0.999 * numel ( fullmri ) ), 1 );

fullmri    = floor ( ( fullmri * 255 ) / maxval );
fullmri    = min ( fullmri, 255 );


% Gets a estimation of the brain.
brainmask  = mri.white + mri.gray + mri.csf > 128;

% Gets the thresholds from the MRI without brain.
brainstrip = fullmri;
brainstrip ( brainmask ) = 0;

lST = floor ( mean ( brainstrip ( brainstrip > 0 ) ) );
uST = floor ( mean ( brainstrip ( brainstrip > lST ) ) );
sT  = floor ( ( lST + uST ) / 2 );


% Gets the scalp.
scalpmask  = fullmri >= sT;
scalpmask  = scalpmask | mymop_dilate26 ( brainmask );
scalpmask  = scalpmask | mymop_dilate26 ( mri.white + mri.gray + mri.csf + mri.bone > 128 );
scalpmask ( :, 10, : ) = true;

% Fixes the scalp.
scalpmask  = dilateO2 ( scalpmask );
scalpmask  = imfill   ( scalpmask, 'holes' );
scalpmask  = erodeO2  ( scalpmask );

% Gets the biggest connected element.
scalpmask  = bwlabeln ( scalpmask, 6 );
scalpmask  = scalpmask == mode ( scalpmask ( scalpmask ~= 0 ) );


% Gets the first estimation for the skull mask.
skullmask  = fullmri < lST;

% Forces the minimum skull thickness.
skullmask  = skullmask | mymop_dilate26 ( dilateC ( brainmask ) );


% Gets an eroded version of the scalp as an upper boundary for the skull.
skullmax   = scalpmask;
skullmax   = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax );
skullmax   = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax );
skullmax   = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax );
skullmax   = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax ); skullmax = mymop_erode26  ( skullmax );
skullmax   = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax );
skullmax   = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax );
skullmax   = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax ); skullmax = mymop_dilate26 ( skullmax );
skullmax   = mymop_dilate26 ( skullmax );

% Forces the minimum scalp thickness.
skullmask  = skullmask & skullmax;

% Gets the biggest connected element.
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = ( skullmask == mode ( skullmask ( skullmask ~= 0 ) ) );

% Fixes the skull.
skullmask  = mymop_dilateO2 ( skullmask );
skullmask  = mymop_dilateO2 ( skullmask );
skullmask  = mymop_erodeO2  ( skullmask );
skullmask  = mymop_erodeO2  ( skullmask );

% Forces the minimum scalp thickness.
skullmask  = skullmask & skullmax;


% % Gets the inner skull.
% duramask   = fullmri >= lST;
% 
% % Forces the minimum skull thickness.
% duramask   = duramask & skullmask;
% 
% duramask   = duramask | dilateC ( brainmask );
% 
% duramask   = erodeO2  ( duramask );
% duramask   = erodeO2  ( duramask );
% duramask   = dilateO2 ( duramask );
% duramask   = dilateO2 ( duramask );
% 
% duramask   = duramask | erodeO2 ( erodeO2 ( skullmask ) );
% % skullmask  = dilateC ( skullmask );
% 
% % Corrects the masks.
% duramask   = duramask | dilateC ( brainmask );
% skullmask  = skullmask | dilateC ( duramask );
% scalpmask  = scalpmask | dilateC ( skullmask );


% skull = skullmask;
% ft_write_mri ( 'skull_BS.nii', skull, 'dataformat', 'nifti', 'transform', mri.transform );
