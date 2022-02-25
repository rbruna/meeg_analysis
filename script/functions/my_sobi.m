% sobi() - Second Order Blind Identification (SOBI) by joint diagonalization of
%          correlation  matrices. THIS CODE ASSUMES TEMPORALLY CORRELATED SIGNALS,
%          and uses correlations across times in performing the signal separation.
%          Thus, estimated time delayed covariance matrices must be nonsingular
%          for at least some time delays.
% Usage:
%         >> winv = sobi(data);
%         >> [winv,act] = sobi(data,n,p);
% Inputs:
%   data - data matrix of size [m,N] ELSE of size [m,N,t] where
%                m is the number of sensors,
%                N is the  number of samples,
%                t is the  number of trials (avoid epoch boundaries)
%         n - number of sources {Default: n=m}
%         p - number of correlation matrices to be diagonalized
%             {Default: min(100, N/3)} Note that for non-ideal data,
%             the authors strongly recommend using at least 100 time delays.
%
% Outputs:
%   winv - Matrix of size [m,n], an estimate of the *mixing* matrix. Its
%          columns are the component scalp maps. NOTE: This is the inverse
%          of the usual ICA unmixing weight matrix. Sphering (pre-whitening),
%          used in the algorithm, is incorporated into winv. i.e.,
%
%             >> icaweights = pinv(winv); icasphere = eye(m);
%
%   act  - matrix of dimension [n,N] an estimate of the source activities
%
%             >> data            = winv            * act;
%                [size m,N]        [size m,n]        [size n,N]
%             >> act = pinv(winv) * data;
%
% Authors:  A. Belouchrani and A. Cichocki (references: See function body)
% Note:     Adapted by Arnaud Delorme and Scott Makeig to process data epochs by
%           computing covariances while respecting epoch boundaries.

% REFERENCES:
% A. Belouchrani, K. Abed-Meraim, J.-F. Cardoso, and E. Moulines, ``Second-order
%  blind separation of temporally correlated sources,'' in Proc. Int. Conf. on
%  Digital Sig. Proc., (Cyprus), pp. 346--351, 1993.
%
%  A. Belouchrani and K. Abed-Meraim, ``Separation aveugle au second ordre de
%  sources correlees,'' in  Proc. Gretsi, (Juan-les-pins),
%  pp. 309--312, 1993.
%
%  A. Belouchrani, and A. Cichocki,
%  Robust whitening procedure in blind source separation context,
%  Electronics Letters, Vol. 36, No. 24, 2000, pp. 2050-2053.
%
%  A. Cichocki and S. Amari,
%  Adaptive Blind Signal and Image Processing, Wiley,  2003.

% Authors note:
% For non-ideal data, use at least p=100 time-delayed covariance matrices.

function [ H, S ] = my_sobi ( data, sources, p )
%#ok<*INUSL,*NASGU>

% Checks that the number of arguments is correct.
narginchk  ( 1, 3 );
nargoutchk ( 0, 2 );

% Gets the metadata.
[ channels, samples, trials ]= size ( data );

% If no number of lags provided, uses 100 or one third of the data.
if nargin < 3
    p = min ( 100, ceil ( samples / 3 ) );
end

% If no number of sources provided, uses as many sources as sensors.
% The number of sources set here do not affect the program.
if nargin < 2
    sources = channels;
end


% Demeans the data.
data = bsxfun ( @minus, data, mean ( data, 2 ) );

% Pre-whitens the data using SVD.
[ ~, S, V ] = svd ( data ( :, : )', 0 );
W = pinv ( S ) * V';
data ( :, : ) = W * data ( :, : );


% Estimates the correlation matrices for each lag.
M  = zeros ( p, channels, channels, class ( data ) );

for lag = 1: p
    
    % Claculates the cross unbiased correlation.
    data1 = data ( :, lag + 1: samples, : );
    data2 = data ( :, 1: samples - lag, : );
    Rxp   = data1 ( :, : ) * data2 ( :, : )' / trials;
    Rxp   = Rxp / ( samples - lag );
    
    % Stores the normalized correlation for this lag.
    % Frobenius norm = sqrt(sum(diag(Rxp'*Rxp)))
    M ( lag, :, : ) = Rxp * norm ( Rxp, 'fro' );
end


% Initializes the mixing matrix to the identity matrix.
V = eye ( channels );

% Initializes the iteration flag and the iteration number.
iter = 0;
loop = true;

% Sets the stop condition for the iterative algorithm.
epsil  = 1 / sqrt ( samples ) / 100;
epsil2 = epsil^2;


% Performs the joint diagonalization.
while loop
    
    % Resets the iteration flag and updates the iteration index.
    iter = iter + 1;
    loop = false;
    
    % Writes out the iteration.
    text = sprintf ( 'Iteration %i...', iter );
    fprintf ( 1, '%s', text );
    
    for p = 1: channels - 1
        for q = p + 1: channels
            
            % Computes the degree of independence between the sources.
            g1 = M ( :, p, p ) - M ( :, q, q );
            g2 = M ( :, p, q ) + M ( :, q, p );
            g3 = M ( :, q, p ) - M ( :, p, q );
            
            g  = [ g1 g2 g3 ]';
            gg = g * g'.* [ 1 1 0; 1 1 0; 0 0 1 ];
            
            % Generates the Givens rotation from the main eigenvector.
            [ angles, ~ ] = eig ( gg, 'nobalance' );
            angles = sign ( angles ( 1, 3 ) ) * angles;
            
            c  = sqrt ( 0.5 + angles ( 1, 3 ) / 2 );
            sr = 0.5 * ( angles ( 2, 3 ) - 1i * angles ( 3, 3 ) ) / c;
            sc = 0.5 * ( angles ( 2, 3 ) + 1i * angles ( 3, 3 ) ) / c;
            
            
            % Performs the rotation, if needed.
            if sc * sr > epsil2
                
                % If at least one element was modified iterates again.
                loop = true;
                
                % Rotates the correlation matrix along the column dimension.
                colp = M ( :, :, p );
                colq = M ( :, :, q );
                M ( :, :, p ) = c * colp + sr * colq;
                M ( :, :, q ) = c * colq - sc * colp;
                
                % Rotates the correlation matrix along the row dimension.
                rowp = M ( :, p, : );
                rowq = M ( :, q, : );
                M ( :, p, : ) = c * rowp + sc * rowq;
                M ( :, q, : ) = c * rowq - sr * rowp;
                
                % Rotates the mixing matrix.
                Vp   = V ( :, p );
                Vq   = V ( :, q );
                V ( :, p ) = c * Vp + sr * Vq;
                V ( :, q ) = c * Vq - sc * Vp;
            end
        end
    end
    
    % Removes the iteration information by writing backspaces.
    text = repmat ( sprintf ( '\b' ), size ( text ) );
    fprintf ( 1, '%s', text );
end

% Writes out the total number of iterations.
text = sprintf ( 'Finished in %i iterations.\n', iter );
fprintf ( 1, '%s', text );

% Estimates the mixing matrix.
H = pinv ( W ) * V;

% Estimates the source activities, if required.
if nargout > 1
    S = data;
    S ( :, : ) = V' * data ( :, : );
end
