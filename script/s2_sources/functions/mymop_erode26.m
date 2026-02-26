function volume = mymop_erode26 ( volume )

% Performs morphological erosion a binary 3D volume using a cubic
% structuring element (26-connectivity).

% Adds a zero padding to each dimension of the image.
volume  = mymop_addpad3 ( volume, 1 );

% Creates shifted versions of the image.
volume1 = circshift ( volume, [  1  0  0 ] );
volume2 = circshift ( volume, [ -1  0  0 ] );

% Applies the binary erosion.
volume  = volume & volume1 & volume2;

% Creates shifted versions of the image.
volume1 = circshift ( volume, [  0 -1  0 ] );
volume2 = circshift ( volume, [  0  1  0 ] );

% Applies the binary erosion.
volume  = volume & volume1 & volume2;

% Creates shifted versions of the image.
volume1 = circshift ( volume, [  0  0  1 ] );
volume2 = circshift ( volume, [  0  0 -1 ] );

% Applies the binary erosion.
volume  = volume & volume1 & volume2;

% Removes the padding.
volume  = mymop_rmpad3 ( volume, 1 );
