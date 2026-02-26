function trans = my_pos2neuromag ( fid )

% Based on FieldTrip 20190705 functions:
% * ft_headcoordinates by Robert Oostenveld



% Gets the three Neuromag fiducials.
nas   = fid.pos ( strcmpi ( fid.label, 'Nasion' ), : );
lpa   = fid.pos ( strcmpi ( fid.label, 'LPA' ), : );
rpa   = fid.pos ( strcmpi ( fid.label, 'RPA' ), : );

% Gets the three axis.
axisx = rpa - lpa;
axisz = cross ( axisx, nas - lpa );
axisy = cross ( axisz, axisx );

% Normalizes the axis.
axisx = axisx / norm ( axisx );
axisy = axisy / norm ( axisy );
axisz = axisz / norm ( axisz );

% Determines the origin.
orig  = lpa + dot ( nas-lpa, axisx ) * axisx;

% Calculates the rotation matrix.
rot   = eye (4);
rot ( 1: 3, 1: 3 ) = inv ( eye (3) / cat ( 1, axisx, axisy, axisz ) );

% Calculates the translation matrix.
tra   = eye (4);
tra ( 1: 3, 4 ) = -orig';

% Creates the affine transformation matrix.
trans = rot * tra;
