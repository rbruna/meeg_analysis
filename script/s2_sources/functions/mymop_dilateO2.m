function volume = mymop_dilateO2 ( volume )

% Performs morphological dilation a binary 3D volume using a 5-radius
% sphere as structuring element.

volume = mymop_dilate06 ( volume );
volume = mymop_dilate06 ( volume );
volume = mymop_dilate26 ( volume );
volume = mymop_dilate26 ( volume );
