function [ skullmask, duramask ] = my_getSkullHS ( mri )

% Gets a skull estimation using Hybrid Segmentation algorithm.

% Based on function:
% * hybrid_seg by KL Perdue

% Perdue KL, Diamond SG; 
% T1 magnetic resonance imaging head segmentation for diffuse optical tomography and electroencephalography. 
% J. Biomed. Opt. 19(2):026011.  doi:10.1117/1.JBO.19.2.026011.


fprintf ( 1, 'Creating a mask for the brain.\n' );

% Creates the brain mask. Uses FreeSurfer segmentation if available.
if isfield ( mri, 'aseg' )
    brainmask = mri.aseg ~= 0;
else
    brainmask = ( mri.gray + mri.white ) > 128;
end

% Fixes the mask.
brainmask  = mymop_dilate26 ( brainmask );
brainmask  = imfill ( brainmask, 'holes' );
brainmask  = mymop_erode26  ( brainmask );

% Gets the scalp mask.
scalpmask  = mri.scalp;
scalpmask  = mymop_dilate06 ( scalpmask );


fprintf ( 1, 'Creating a mask for the outter skull.\n' );

% Removes both the outter space and the brain.
headonly   = mri.anatomy .* ( scalpmask & ~brainmask );

% Takes the 25% darkest points.
dummy      = sort ( headonly ( headonly ~= 0 ) );
thresh2    = dummy ( round ( .25 * length ( dummy ) ) );

% Gets the points bellow the threshold.
skullmask  = ( headonly < thresh2 ) | brainmask;


fprintf ( 1, 'Fixing errors in the outter skull mask.\n' );

% Gets an eroded version of the scalp as an upper boundary for the skull.
skullmax   = scalpmask;
skullmax   = mymop_erode26 ( skullmax ); skullmax = mymop_erode26 ( skullmax ); skullmax = mymop_erode26 ( skullmax );
skullmax   = mymop_erode26 ( skullmax ); skullmax = mymop_erode26 ( skullmax );

% Forces the minimum scalp thickness to 5 mm.
skullmask  = skullmask & skullmax;

% Fixes the mask.
skullmask  = mymop_dilate26 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erode26  ( skullmask );

% Gets the biggest connected element.
skullmask  = bwlabeln ( skullmask, 6 );
skullmask  = ( skullmask == mode ( skullmask ( skullmask ~= 0 ) ) );

% Smooths the mask.
skullmask  = smoothR  ( skullmask );
skullmask  = smoothR  ( skullmask );

% Creates a surface based on the mask.
opt.radbound  = 4;
opt.distbound = 1;
[ pnt, tri ]  = v2s ( skullmask, 0.75, opt );

% Creates a volume based on the surface.
skullmask  = surf2vol ( pnt, tri, -1: mri.dim (1) - 2, -1: mri.dim (2) - 2, -1: mri.dim (3) - 2 );

% Fixes the mask.
skullmask  = mymop_dilate26 ( skullmask );
skullmask  = imfill ( skullmask, 'holes' );
skullmask  = mymop_erode26  ( skullmask );

% Forces the minimum scalp thickness to 5 mm.
skullmask  = skullmask & skullmax;


fprintf ( 1, 'Creating a mask for the inner skull.\n' );

% Removes anything outside the skull.
headonly   = mri.anatomy .* mymop_erode06 ( skullmask );

% Creating a mask for the inner skull.
duramask   = ( headonly > thresh2 ) | mymop_erode06 ( brainmask );


fprintf ( 1, 'Fixing errors in the inner skull mask.\n' );

% Gets an eroded version of the outter skull as an upper boundary for the
% inner skull.
iskullmin  = scalpmask;
iskullmin  = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin );
iskullmin  = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin );
iskullmin  = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin );
iskullmin  = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin );
iskullmin  = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin ); iskullmin = mymop_erode26 ( iskullmin );


% Forces the minimum CSF thickness to 1 mm.
duramask   = duramask | mymop_dilate06 ( brainmask );

% Forces the maximum skull thickness to 15 mm.
duramask   = duramask | iskullmin;

% Gets the biggest connected element.
duramask   = bwlabeln ( duramask, 6 );
duramask   = ( duramask == mode ( duramask ( duramask ~= 0 ) ) );

% Smooths the mask.
duramask   = smoothR  ( duramask );
duramask   = smoothR  ( duramask );

% Creates a surface based on the mask.
opt.radbound  = 2;
opt.distbound = 1;
[ pnt, tri ]  = v2s ( duramask, 0.48, opt );

% Creates a volume based on the surface.
duramask   = surf2vol ( pnt, tri, -1: mri.dim (1) - 2, -1: mri.dim (2) - 2, -1: mri.dim (3) - 2 );

% Fixes the mask.
duramask   = mymop_dilate26 ( duramask );
duramask   = imfill ( duramask, 'holes' );
duramask   = mymop_erode26  ( duramask );

% Forces the minimum CSF thickness to 1 mm.
duramask   = duramask | mymop_dilate06 ( brainmask );

% Forces the maximum skull thickness to 15 mm.
duramask   = duramask | iskullmin;



% skull = skullmask;
% ft_write_mri ( 'skull_HS.nii', skull, 'dataformat', 'nifti' );
