function volume = mymop_rmpad3 ( volume, npad )

% Function to remove the padding of a 3D volume.

% Checks that the input is a 3D volume.
if ndims ( volume ) ~= 3
    error ( 'This function requires a 3-D matrix as input.' )
end

% Checks that the padding is less than half the data.
if npad >= floor ( min ( size ( volume ) ) )
    error ( 'Defined padding is too large for this volume.' )
end


% Removes the padding.
volume = volume ( ...
    npad + 1: end - npad, ...
    npad + 1: end - npad, ...
    npad + 1: end - npad );
