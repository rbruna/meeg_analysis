function sources = my_beamformer ( cfg, srcmodel, data )

% Checks the inputs.
if ~ft_datatype ( data, 'timelock' )
    error ( 'This function only works with LCMV beamformer for now.' )
end


% Sets he default parameters.
if ~isfield ( cfg, 'keepfilter' ),   cfg.keepfilter   = true;    end
if ~isfield ( cfg, 'keepmom' ),      cfg.keepmom      = false;   end
if ~isfield ( cfg, 'projectmom' ),   cfg.projectmom   = false;   end
if ~isfield ( cfg, 'keepcov' ),      cfg.keepcov      = false;   end
if ~isfield ( cfg, 'keepnoise' ),    cfg.keepnoise    = false;   end
if ~isfield ( cfg, 'projectnoise' ), cfg.projectnoise = false;   end
if ~isfield ( cfg, 'powmethod' ),    cfg.powmethod    = 'trace'; end

% Gets the options as booleans, if required.
if ischar ( cfg.keepfilter ),   cfg.keepfilter   = strcmp ( cfg.keepfilter,   'yes' ); end
if ischar ( cfg.keepmom ),      cfg.keepmom      = strcmp ( cfg.keepmom,      'yes' ); end
if ischar ( cfg.projectmom ),   cfg.projectmom   = strcmp ( cfg.projectmom,   'yes' ); end
if ischar ( cfg.keepcov ),      cfg.keepcov      = strcmp ( cfg.keepcov,      'yes' ); end
if ischar ( cfg.keepnoise ),    cfg.keepnoise    = strcmp ( cfg.keepnoise,    'yes' ); end
if ischar ( cfg.projectnoise ), cfg.projectnoise = strcmp ( cfg.projectnoise, 'yes' ); end


% Gets the whitener, if provided.
if isfield ( cfg, 'subspace' ) && ~isempty ( cfg.subspace )
    whitener = cfg.subspace;
else
    whitener = eye ( size ( data.cov ) );
end

% Calculates the whitened covariance matrix.
wcov = whitener * data.cov * whitener';


% Gets the regularization parameter, if provided.
if isfield ( cfg, 'lambda' )
    
    % If numeric, takes the value of lambda.
    if isnumeric ( cfg.lambda )
        lambda = cfg.lambda;
        
    % If percent, calculates the value of lambda.
    elseif ischar ( cfg.lambda ) && strcmp ( cfg.lambda ( end ), '%' )
        ratio  = str2double ( cfg.lambda ( 1: end - 1 ) ) / 100;
        lambda = ratio * trace ( wcov ) / size ( wcov, 1 );
    end
else
    lambda = 0;
end

if ~isequal ( whitener, diag ( diag ( whitener ) ) ) && lambda ~= 0
    warning ( 'Using both data whitening and Tikhonov regularization.' )
end

% Calculates the (regularized) inverse of the covariance matrix.
% icov = pinv ( whitener * data.cov * whitener' );
icov = pinv ( wcov + lambda * eye ( size ( wcov ) ) );


% Estimates the channel-level noise.
noise = svd ( data.cov );
noise = noise ( end );
noise = max ( noise, lambda );


% Initializes the sources structure.
sources          = [];
sources.label    = srcmodel.label;
sources.pos      = srcmodel.pos;
if isfield ( srcmodel, 'tri' ),    sources.tri    = srcmodel.tri;    end
if isfield ( srcmodel, 'nrm' ),    sources.nrm    = srcmodel.nrm;    end
if isfield ( srcmodel, 'inside' ), sources.inside = srcmodel.inside; end
if isfield ( srcmodel, 'unit' ),   sources.unit   = srcmodel.unit;   end

if cfg.keepfilter
    sources.filter   = cell ( size ( srcmodel.leadfield (:) ) );
end
if cfg.keepnoise
    sources.noise    = nan  ( size ( srcmodel.leadfield (:) ) );
end
if cfg.keepcov
    sources.cov      = cell ( size ( srcmodel.leadfield (:) ) );
end
if cfg.keepnoise && cfg.keepcov
    sources.noisecov = cell ( size ( srcmodel.leadfield (:) ) );
end
if cfg.keepmom
    sources.mom      = cell ( size ( srcmodel.leadfield (:) ) );
    sources.pow      = nan  ( size ( srcmodel.leadfield (:) ) );
    if isfield ( data, 'time' )
        sources.time     = data.time;
    end
else
    sources.pow      = nan  ( size ( srcmodel.leadfield (:) ) );
end


% Goes through each source position.
for c = find ( srcmodel.inside (:) )'
    
    % Gets the (whitened) leadfield for the current dipole.
    dipleadfield = whitener * srcmodel.leadfield { c };
    
    % Calculates the (unwhitened) beam former filter.
    dipfilter    = pinv ( dipleadfield' * icov * dipleadfield ) * dipleadfield' * icov * whitener;
    
    % Calculates the sources' power and noise.
    dippowercov  = dipfilter * data.cov * dipfilter';
    dipnoisecov  = noise * ( dipfilter * dipfilter' );
    
    % Projects over the dominant direction, if requested.
    if cfg.projectmom
        
        % Calculates the projection over the dominant direction.
        [ u, ~ ]     = svd ( dippowercov );
        u            = u ( :, 1 );
        
        % Projects the data and the noise.
        dipfilter    = u' * dipfilter;
        dippowercov  = u' * dippowercov * u;
        dipnoisecov  = u' * dipnoisecov * u;
    end
    
    % Calculates the dipole power.
    if strcmp ( cfg.powmethod, 'lambda1' )
        dippow       = max ( svd ( dippowercov ) );
        dipnoise     = max ( svd ( dipnoisecov ) );
    else
        dippow       = trace ( dippowercov );
        dipnoise     = trace ( dipnoisecov );
    end
    
    % Stores the spatial filter, if required.
    if cfg.keepfilter
        sources.filter   { c } = dipfilter;
    end
    
    % Stores the extra information.
    if cfg.keepnoise
        sources.noise    ( c ) = dipnoise;
    end
    if cfg.keepcov
        sources.cov      { c } = dippowercov;
    end
    if cfg.keepnoise && cfg.keepcov
        sources.noisecov { c } = dipnoisecov;
    end
    if cfg.keepmom
        sources.mom      { c } = dipfilter * data.avg;
        sources.pow      ( c ) = dippow;
    end
end
