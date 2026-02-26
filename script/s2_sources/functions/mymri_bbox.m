function bbox = mymri_bbox ( mri )

% Defines the bounding box (corners in real-world units) of an MRI.

% Defines the maximum and minimum voxel for each dimension.
maxmin = cat ( 1, [ 1 1 1 ], mri.dim ( 1: 3 ) );

% Gets the voxel coordinate for each corner.
bvox1  = maxmin ( [ 1 1 1 1 2 2 2 2 ], 1 );
bvox2  = maxmin ( [ 1 1 2 2 1 1 2 2 ], 2 );
bvox3  = maxmin ( [ 1 2 1 2 1 2 1 2 ], 3 );

% Convers the voxel coordinates into real-world coordinates.
mrirot = mri.transform ( 1: 3, 1: 3 )';
mritra = mri.transform ( 1: 3, 4 )';
bbox   = [ bvox1 bvox2 bvox3 ] * mrirot + mritra;
