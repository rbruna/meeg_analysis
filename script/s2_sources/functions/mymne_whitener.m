function whitener = mymne_whitener ( timelock )

% Gets the sensor type.
senstype = my_senstype ( timelock.label );

% Gets the covariance matrix, if provided.
if isfield ( timelock, 'cov' )
    cov = timelock.cov;
else
    cov = mymne_adhoccov ( senstype );
end

% Calculates the rank of the covariance matrix.
scales   = mymne_scales ( senstype );
sigma    = svd ( cov .* scales );
% rank     = sum ( sigma > size ( cov, 1 ) * max ( abs ( sigma ) ) * eps );
rank     = sum ( sigma > 1e-4 );

% dlsigma  = diff ( log ( sigma ) );
% rank     = find ( dlsigma < 2 * min ( dlsigma ( 1: 5 ) ), 1 );
% rank = 297;


% Creates the whitening matrix using PCA.
[ u, s ] = svd ( cov );
s = diag ( s );
s ( rank + 1: end ) = inf;
% whitener = u * sqrt ( diag ( 1 ./ s ) ) * u';
whitener = sqrt ( diag ( 1 ./ s ) ) * u';

% % MNE-C way.
% whitener = sqrt ( diag ( 1 ./ s ) );
% whitener ( rank + 1: end, rank + 1: end ) = 0;
% whitener = whitener * u';


function scales = mymne_scales ( senstype )

% Iitializes the channel scales.
scales  = ones ( size ( senstype ) );

% Sets the default scale for each sensor type.
scales ( strcmp ( senstype, 'megmag'    ) ) = 1e12;
scales ( strcmp ( senstype, 'megplanar' ) ) = 1e11;
scales ( strcmp ( senstype, 'eeg'       ) ) = 1e05;

% Calculates the scaling matrix.
scales  = scales * scales';


function cov = mymne_adhoccov ( senstype )

% Inializes the channel variances.
precov  = ones ( size ( senstype ) );

% Sets the default variance for each sensor type.
precov ( strcmp ( senstype, 'megmag'    ) ) = 2e-14;
precov ( strcmp ( senstype, 'megplanar' ) ) = 5e-13;
precov ( strcmp ( senstype, 'eeg'       ) ) = 2e-07;

% Calculates the covariance matrix.
cov     = diag ( precov .^ 2 );


function senstype = my_senstype ( label )

% Initializes the output.
senstype = cell ( 102, 1 );
senstype (:) = { 'unkwnown' };

if ~ft_senstype ( label, 'neuromag306' )
    warning ( 'Unknown system.' );
    return
end

% Detects the EEG channels.
eegchan  = strncmp ( label, 'EEG', 3 );
senstype ( eegchan ) = { 'eeg' };

% Fetects the magnetometers.
magchan  = ~cellfun ( @isempty, regexp ( label, '^MEG.*1$' ) );
senstype ( magchan ) = { 'megmag' };

% Detects the planar gradiometers.
gradchan  = ~cellfun ( @isempty, regexp ( label, '^MEG.*[23]$' ) );
senstype ( gradchan ) = { 'megplanar' };
