function output = myss_aux_leadsphere_chans ( xpos, senspos, sensori )

% Based on FiedTrip functions:
% * leadsphere_chans by Guido Nolte

% Permutes the sensors matrices to simplify calculations.
senspos = permute ( senspos, [ 1 3 2 ] );
sensori = permute ( sensori, [ 1 3 2 ] );

% Calculates the distance between sensors and locations.
radi    = sqrt ( sum ( senspos .^ 2 ) );
vect    = bsxfun ( @minus, senspos, xpos );
proj    = dot3d ( vect, senspos );
dist    = sqrt ( sum ( vect .^ 2 ) );

% Calculates the gradient functions.
% senspos * ( ( dist^2 ) / radi + proj / dis + 2*dist + 2*radi ) - xpos * ( 2*radi + dist + proj/dist )
gradf1  = bsxfun ( @rdivide, dist .^ 2, radi );
gradf2  = bsxfun ( @plus, proj ./ dist + 2 * dist, 2 * radi );
gradf3  = gradf1 + gradf2;
gradf4  = bsxfun ( @plus, 2 * radi, dist + proj ./ dist );
gradf   = bsxfun ( @times, gradf3, senspos ) - bsxfun ( @times, gradf4, xpos );

% Calculates the output.
output1 = 1 ./ ( bsxfun ( @times, radi, dist.^ 2 ) + proj .* dist );
output2 = output1 .^ 2;
output3 = cross3d ( xpos, sensori );
output4 = dot3d ( gradf, sensori );
output5 = cross3d ( xpos, senspos );
output  = bsxfun ( @times, output3, output1 ) - bsxfun ( @times, output4 .* output2, output5 );

%GRB change
output  = output * 1e-7;


function cross = cross3d ( vector1, vector2 )

X1 = bsxfun ( @times, circshift ( vector1, -1 ), circshift ( vector2,  1 ) );
X2 = bsxfun ( @times, circshift ( vector1,  1 ), circshift ( vector2, -1 ) );

cross = X1 - X2;


function dot = dot3d ( vector1, vector2 )

dot = sum ( bsxfun ( @times, vector1, vector2 ) );
