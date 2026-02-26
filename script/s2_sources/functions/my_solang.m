function w = my_solang ( r1, r2, r3 )

% Based on FieldTrip functions:
% * solid_angle by  Robert Oostenveld

% If two inputs, reasigns the inputs.
if nargin == 2
    pnt = r1;
    tri = r2;
    
    % Gets the list of points for each triangle.
    r1 = pnt ( tri ( :, 1 ), : );
    r2 = pnt ( tri ( :, 2 ), : );
    r3 = pnt ( tri ( :, 3 ), : );
end

cp23 = cross ( r2, r3 );
nom  = sum ( cp23 .* r1, 2 );

n1   = sqrt ( sum ( r1 .^ 2, 2 ) );
n2   = sqrt ( sum ( r2 .^ 2, 2 ) );
n3   = sqrt ( sum ( r3 .^ 2, 2 ) );
ip12 = sum ( r1 .* r2, 2 );
ip23 = sum ( r2 .* r3, 2 );
ip31 = sum ( r3 .* r1, 2 );
den  = n1 .* n2 .* n3 + ip12 .* n3 + ip23 .* n1 + ip31 .* n2;

w    = -2 * atan2 ( nom, den );

% Corrects the invalid values.
w ( nom == 0 & den <= 0 ) = nan;
