function brainmask = my_getBrainpCT ( mri )

% Gets the estimation of the outer skull.
skullpos   = strcmpi ( mri.masklabel, 'skull pseudoCT' );
skullmask  = mri.mask ( :, :, :, skullpos );

% Gets the CT information.
brainmask  = mri.pct;

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

% Adds the FreeSurfer gray matter constrain.
if isfield ( mri, 'aseg' )
    asegmask  = my_getBrainFS ( mri );
    brainmask = brainmask | mymop_dilate26 ( asegmask );
end
