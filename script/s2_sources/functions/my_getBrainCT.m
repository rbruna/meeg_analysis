function brainmask = my_getBrainCT ( mri )

% Gets the estimation of the outer skull.

% Gets the estimation of the outer skull.
skullpos   = strcmpi ( mri.masklabel, 'skull CT' );
skullmask  = mri.mask ( :, :, :, skullpos );

% Gets the CT information.
brainmask  = mri.ct;

% Keeps only the compartment inside the skull.
brainmask ( ~mymop_erode26 ( skullmask ) ) = -inf;

% Gets the soft tissue.
brainmask  = brainmask > -100 & brainmask < 300;


% Gets only the biggest connected element.
brainmask  = mymop_erodeO2 ( brainmask );
brainmask  = bwlabeln ( brainmask, 6 );
brainmask  = brainmask == mode ( brainmask ( brainmask (:) > 0 ) );
brainmask  = mymop_dilateO2 ( brainmask );

% Closes holes.
brainmask  = imfill ( brainmask, 'holes' );
