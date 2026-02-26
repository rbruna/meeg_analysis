function whitener = my_whitener ( timelock, varargin )

% whitener = my_whitener ( timelock, label )
% whitener = my_whitener ( timelock, type )
% whitener = my_whitener ( timelock, label, type )
% 
% This function can perform three types of whitening:
% * 1: OSL no-whitening: Only scales the sensor types (default).
% * 2: PCA whitener: Reduces, if needed, the number of channels.
% * 3: Full whitener: Produces a rank-deficient covariance matrix.

% Sets the default parameters.
if numel ( varargin ) && iscellstr ( varargin {1} )
    label    = varargin {1};
    varargin = varargin ( 2: end );
else
    label    = timelock.label;
end
if numel ( varargin ) && isnumeric ( varargin {1} ) && isscalar ( varargin {1} )
    type     = varargin {1};
    varargin = varargin ( 2: end );
else
    type     = 1;
end
if numel ( varargin ) && islogical ( varargin {1} ) && isscalar ( varargin {1} )
    raw      = varargin {1};
else
    raw      = false;
end

% If nothing to do, exits.
if raw && type == 0
    whitener       = [];
    return
end


% Extracts the covariance matrix for the selected channels.
index    = my_matchstr ( timelock.label, label );
cov      = timelock.cov ( index, index );


% Scales the channels.
if type > 0
    
    % Normalizes MEGMAG, MEGGRAD and EEG separately.
    types    = { 'MEGMAG', 'MEGGRAD', 'EEG' };
    scales   = ones ( numel ( index ), 1 );
    
    % Goes through each channel type.
    for tindex = 1: numel ( types )
        
        % Gets the covariance matrix.
        channel  = ft_channelselection ( types { tindex }, label );
        index    = ismember ( label, channel );
        subcov   = cov ( index, index );
        
        % Estimates the scaling from the eigenvalues.
        svds     = svd ( subcov );
        svds     = svds ( 1: my_rank ( svds ) );
        scale    = 1 ./ sqrt ( max ( svds ) );
        
        % Saves the scaling value.
        scales ( index ) = scale;
    end
    
    % Converts the scaling to a matrix.
    scales   = diag ( scales );
else
    scales   = eye ( size ( cov ) );
end


% Applies MNE whitening, if requested.
if type > 1
    
    % Calculates the SVD decomposition.
    [ u, s, v ] = svd ( scales * cov * scales' );
    u        = u';
    s        = diag ( s );
    v        = v';
    
    % Normalizes the matrix using PCA.
    rank     = my_rank ( s );
    u        = u ( 1: rank, : );
    s        = s ( 1: rank );
    v        = v ( :, 1: rank );
    
    % Builds the whitening matrix.
    mat      = diag ( sqrt ( 1 ./ s ) ) * u;
    
    % Applies the original scaling.
    mat      = mat * scales;
    
    
    % Applies full whitening, if requested.
    if type > 2
        
        % Goes back to the original space, if requested.
        mat      = v * mat;
    end
else
    mat      = scales;
end


% Stores the result.
whitener = [];
whitener.label = label;
whitener.cov   = cov;
whitener.mat   = mat;
whitener.wcov  = mat * cov * mat';

% If raw output requested, outputs only the whitening matrix.
if raw
    whitener       = whitener.mat;
end
