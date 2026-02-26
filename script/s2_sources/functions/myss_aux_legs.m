function [ basis, gradbasis ] = myss_aux_legs ( xpos, xori, order, scale )
% usage: [basis,gradbasis]=legs(x,dir,n,scale)
%
% returns the values and directional derivatives  of (n+1)^2-1 basis functions 
% constructed from spherical harmonics at locations given in x and, for the 
% gradients, for (in general non-normalized) directions given in dir.   
% 
% input: x      set of N locations given as an Nx3 matrix 
%        dir    set of N direction vectors given as an Nx3 matrix 
%                  (dir is not normalized (it hence can be a dipole moment))
%        n       order of spherical harmonics 
%
% output: basis: Nx((n+1)^2-1)  matrix containing in the j.th  row the real 
%                and imaginary parts of r^kY_{kl}(theta,Phi)/(N_{kl}*scale^k) ( (r,theta,phi) 
%                are the spherical coordinates corresponding to  the j.th row in x) 
%                for k=1 to n and l=0 to k 
%                the order is:
%                          real parts for k=1 and l=0,1 (2 terms) 
%                  then    imaginary parts for k=1 and l=1 (1 term) 
%                  then    real parts for k=2 and l=0,1,2 (3 terms) 
%                  then    imaginary parts for k=2 and l=1,2 (2 term) 
%                              etc.
%                   the spherical harmonics are normalized with
%                   N_{kl}=sqrt(4pi (k+l)!/((k-l)!(2k+1)))
%                    the phase does not contain the usual (-1)^l term !!! 
%                   scale is constant preferably set to the avererage radius                   
%
%         gradbasis: Nx((n+1)^2-1) matrix containing in the j.th row the scalar 
%                     product of the gradient of the former with the j.th row of dir

% Copyright (C) 2003, Guido Nolte

% Based on FiedTrip functions:
% * legs by Guido Nolte


% Calculates the position in spherical coordinates.
[ phi, theta, radi ] = cart2sph ( xpos ( :, 1 ), xpos ( :, 2 ), xpos ( :, 3 ) );
cos_theta   = double ( cos ( pi / 2 - theta ) );

% Calculates the Legendre polinomials for each position.
% basis = zeros ( order, order + 1, numel ( cos_theta ) );
% for i = 1: order
%     basis ( i, 1: i + 1, : ) = legendre ( i, cos_theta );
% end
basis = zeros ( order + 1, order + 1, numel ( cos_theta ) );
for i = 0: order
    basis ( :, i + 1, : ) = my_plgndr ( order, i, cos_theta )';
end

% Discards PX_0.
basis ( 1, :, : ) = [];

% Corrects the polinomials.
ephi  = permute ( exp ( 1i * phi * ( 0: order ) ), [ 3 2 1 ] );
radin = permute ( radi .^ ( 1: order ), [ 2 3 1 ] );
basis = basis .* ( (-1) .^ ( 0: order ) );
basis = basis .* double ( ephi .* radin );


% Calculates the shifting factors.
shifts = ( 1: order )' + ( 1: order + 1 );
shiftfactors = shifts - 1;
shiftminusfactors = ( shifts - 1 ) .* ( shifts - 2 );
shiftminusfactors ( :, 1 ) = 1;

legshift ( 2: order, :, : ) = basis ( 1: order - 1, :, : );
legshift ( 1, 1, : ) = 1;

legshiftplus ( :, 1: order, : ) = - legshift ( :, 2: order + 1, : );
legshiftplus ( :, order + 1, : ) = 0;

legshiftminus ( :, 2: order + 1, : ) = legshift ( :, 1: order, : );
legshiftminus ( :, 1, : ) = -conj ( legshift ( :, 2, : ) );

legshift = legshift .* shiftfactors;
legshiftminus = legshiftminus .* shiftminusfactors;


dirp=[(xori(:,1)+xori(:,2)/1i)/2,(xori(:,1)-xori(:,2)/1i)/2,xori(:,3)];

gradbasis = sum ( permute ( dirp, [ 3 4 1 2 ] ) .* cat ( 4, legshiftplus, legshiftminus, legshift ), 4 );


% Calculates the normalization matrix.
factors = cumprod ( [ 1 1: 2 * order + 1 ] );
normalize = ones ( order, order + 1 );
for i = 1: order
    for j = 1: i + 1
        normalize ( i, j ) = scale ^ i * i * sqrt ( factors ( i + j - 1 + 1 ) / factors ( i - j + 1 + 1 ) / ( 2 * i + 1 ) );
    end
end
normalize ( :, 1 ) = normalize ( :, 1 ) * sqrt (2);

% Normalizes the data.
basis = basis ./ normalize;
gradbasis = gradbasis ./ normalize;

% Packs the complex data as a real 2D matrix.
basis = packdata ( basis );
gradbasis = packdata ( gradbasis );


function packed = packdata ( data )

% Gets the dimensions of the data.
[ x, y, z ] = size ( data );
if x + 1 ~= y, error ( 'Wrong data type.' ); end

% Shifts the dimensions of the data.
data = permute ( data, [ 3 2 1 ] );

% Expands the data in real and imaginary parts.
data = cat ( 2, real ( data ), imag ( data ( :, 2: end, : ) ) );

% Generates the mask.
mask = tril ( true ( x, y ), 1 );
mask = repmat ( mask, 1, 1, z );
mask = permute ( mask, [ 3 2 1 ] );
mask = cat ( 2, mask, mask ( :, 2: end, : ) );

packed = reshape ( data ( mask ), z, [] );
