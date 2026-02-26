function volume = mymop_erodeO2 ( volume )

% Performs morphological erosion a binary 3D volume using a 5-radius sphere
% as structuring element.

volume = mymop_erode06 ( volume );
volume = mymop_erode06 ( volume );
volume = mymop_erode26 ( volume );
volume = mymop_erode26 ( volume );
