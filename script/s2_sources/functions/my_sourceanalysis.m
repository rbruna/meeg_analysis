function source = my_sourceanalysis ( cfg, data, whitener )
% Based on FiedTrip functions:
% * ft_sourceanalysis by Robert Oostenveld


% Checks that the leadfield is computed and all the data is present.
if ~isfield ( cfg, 'grid' ) || ~isfield ( cfg.grid, 'leadfield' )
    error ( 'This function requires a computed leadfield as input.' );
end

% Extracts the grid.
grid = cfg.grid;

% Checks the grid.
if ~isfield ( grid, 'pos' )
    warning ( 'Not dipoles position defined.' );
    grid.pos    = nan ( numel ( grid.leadfield ), 3 );
end
if ~isfield ( grid, 'inside' )
    warning ( 'Not ''inside'' dipoles defined. Considering all the dipoles to be inside.' );
    grid.inside = true ( size ( grid.pos, 1 ), 1 );
end

if ~isfield ( grid, 'label' )
    error ( 'The leadfield channel labels are not defined.' );
end

if numel ( grid.label ) ~= size ( grid.leadfield { find ( grid.inside, 1 ) }, 1 )
    error ( 'The number of channels in the leadfield is different from the number of channel labels.' )
end

if numel ( grid.leadfield ) ~= size ( grid.pos, 1 )
    error ( 'The number of dipoles in the leadfield is different from the number of source positions.' );
end


% Only works with LCMV and DICS beamformers or minimum norm estimators.
if ~ft_datatype ( data, 'timelock' ) && ~ft_datatype ( data, 'freq' )
    error ( 'This function only accepts timelock or time-frequency data as input.' );
end
if isfield ( cfg, 'method' ) && ~ismember ( cfg.method, { 'lcmv' 'dics' 'mne' } )
    error ( 'This function only works with LCMV and DICS beamformers and minimum norm estimators.' );
end

% % Checks that the method is the correct one.
% if ft_datatype ( data, 'timelock' )
%     if ~isfield ( cfg, 'method' )
%         warning ( 'Not method defined. Using LCMV beamformer.' );
%     elseif ~strcmp ( cfg.method, 'lcmv' )
%         warning ( 'Wrong method selected. Changing it to LCMV beamformer' );
%     end
%     cfg.method = 'lcmv';
% end
% if ft_datatype ( data, 'freq' )
%     if ~isfield ( cfg, 'method' )
%         warning ( 'Not method defined. Using DICS beamformer.' );
%     elseif ~strcmp ( cfg.method, 'dics' )
%         warning ( 'Wrong method selected. Changing it to DICS beamformer' );
%     end
%     cfg.method = 'dics';
% end

% Checks that the data is complete for LCMV.
if strcmp ( cfg.method, 'lcmv' )
    
    % Checks the covariance matrix.
    if ~isfield ( data, 'cov' )
        error ( 'Not covariance matrix present in the timelock data.' );
    end
    
    if size ( data.cov, 1 ) ~= size ( data.cov, 2 ) && size ( data.cov, 2 ) ~= size ( data.cov, 3 )
        error ( 'Covariance matrix is not square.' )
    end
    
    if ~isfield ( data, 'label' )
        error ( 'The data channel labels are not defined.' );
    end
    
    if numel ( data.label ) ~= size ( data.cov, 2 )
        error ( 'The dimensions of the covariance matrix do not match the number of channels.' );
    end
end

% Checks that the data is complete for DICS.
if strcmp ( cfg.method, 'dics' )
    
    % Checks the cross spectral density matrix.
    if any ( ~ismember ( data.labelcmb, data.label ) )
        error ( 'Some of the channels in the cross-spectral density matrix are not part of the data.' );
    end
    
    if ~all ( ismember ( data.labelcmb (:), data.label ) )
        warning ( 'Not all the channels are present in the cross-spectral density matrix.' );
    end
    
    % Gets the indexes of the channels in the cross-spectral matrix.
    channel   = intersect ( data.label, data.labelcmb (:) );
    nchannel  = numel ( channel );
    
    % Constructs the cross spectral density matrix.
    [ ~, idx ] = ismember ( data.labelcmb, channel );
    idx       = sub2ind ( [ nchannel nchannel ], idx ( :, 1 ), idx ( :, 2 ) );

    data.csdm = complex ( nan ( nchannel ) );
    data.csdm ( idx ) = data.crsspctrm;
    data.csdm = data.csdm';
    data.csdm ( idx ) = data.crsspctrm;
    data.csdm ( eye ( nchannel ) == 1 ) = data.powspctrm;
    
    if any ( isnan ( data.csdm ) )
        error ( 'Not all the channel combinations are present.' );
    end
end


% Get channels present both in the lead field and the data.
channel = data.label;
channel = intersect ( channel, grid.label, 'stable' );

% Keeps only the common channels.
if ~isequal ( data.label, channel )
    tmpcfg = [];
    tmpcfg.channel = channel;
    data           = ft_selectdata ( tmpcfg, data );
end
if ~isequal ( grid.label, channel )
    tmpcfg = [];
    tmpcfg.channel = channel;
    grid           = ft_selectdata ( tmpcfg, grid );
end

% Re-sorts the lead field to match the data.
if ~isequal ( data.label, grid.label )
    
    % Gets the channel order.
    chidx  = my_matchstr ( grid.label, data.label );
    
    % Re-orders the leadfield.
    grid.label = grid.label ( chidx );
    grid.leadfield ( grid.inside ) = cellfun ( @(x) x ( chidx, : ), grid.leadfield ( grid.inside ), 'UniformOutput', false );
end


% Re-references the EEG data to the average (without bad channels).
if ft_senstype ( data.label, 'eeg' )
%     warning ( 'Re-referencing lead field and data to the average of the used electrodes.' );
    
    % Extracts the lead field.
    leadfield = cat ( 3, grid.leadfield {:} );
    
    % Subtracts the average.
    leadfield = bsxfun ( @minus, leadfield, mean ( leadfield, 1 ) );
    
    % Stores the leadfield in FieldTrip format.
    grid.leadfield ( grid.inside ) = num2cell ( leadfield, [ 1 2 ] );
    
    
    % Generates the common average reference operator.
    nchan     = numel ( grid.label );
    data2car  = eye ( nchan ) - 1 / nchan;
    
    % Re-references the data to the average.
    if strcmp ( cfg.method, 'lcmv' )
        data.cov  = data2car * data.cov * data2car';
    end
    if strcmp ( cfg.method, 'dics' )
        data.csdm = data2car * data.csdm * data2car';
    end
end


% Calculates the sources for each trial.
if strcmp ( cfg.method, 'lcmv' )
    
%     % Creates a dummy data variable.
%     dummy  = zeros ( size ( data.cov, 1 ), 0 );
%     
%     % Calculates the LCMV beam former.
%     extra  = ft_cfg2keyval ( cfg.lcmv );
%     source = beamformer_lcmv ( grid, [], [], dummy, data.cov, extra {:} );
    
    % Calculates the LCMV beam former.
    source = my_beamformer ( cfg.lcmv, grid, data );
end
if strcmp ( cfg.method, 'dics' )
    % Calculates the DICS beam former.
    extra  = ft_cfg2keyval ( cfg.dics );
    source = beamformer_dics ( grid, [], [], [], data.csdm, extra {:} );
end
if strcmp ( cfg.method, 'mne' )
    
    % Calculates the minimum norm estimator.
    source = my_mne ( cfg.mne, grid, data );
end

% Adds the channel order.
source.label = grid.label;
