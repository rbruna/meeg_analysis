function volume = mymop_addpad3 ( volume, npad )

% Function to add padding to a 3D volume.

% Checks that the input is a 3D volume.
if ndims ( volume ) ~= 3
    error ( 'This function requires a 3-D matrix as input.' )
end


% Adds the padding.
volume = padarray ( volume, [ npad npad npad ] );
