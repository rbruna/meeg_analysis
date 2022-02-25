function trialdata = my_EEGreref ( trialdata, config )

% Checks the parameters.
if ~isfield ( config, 'EEGref' ), config.EEGref = false; end
if ~isfield ( config, 'hide' ),   config.hide   = false; end

% If nothing requested exits.
if isequal ( config.EEGref, false ) && isequal ( config.hide, false ), return, end


% Gets the lengths of the trials.
triallen = cellfun ( @(x) size ( x, 2 ), trialdata.trial );

% Concatenates the trials along the second dimension.
trials   = cat ( 2, trialdata.trial {:} );


% Re-references the EEG channels, if requested.
if ~isequal ( config.EEGref, false )
    
    % List the channels to re-reference (EEG minus ignored and bad).
    EEGchans = ft_channelselection ( 'EEG', trialdata.label );
    EEGchans = setdiff   ( EEGchans, config.ignore );
    EEGchans = setdiff   ( EEGchans, config.bad );
    EEGchans = ismember  ( trialdata.label, EEGchans );
    
    % Gets only the EEG data.
    trialEEG = trials ( EEGchans, : );
    
    % Selects the new reference.
    switch config.EEGref
        case { 'average' 'mean' }
            reference = mean   ( trialEEG, 1 );
        case { 'median' }
            reference = median ( trialEEG, 1 );
        otherwise
            error ( 'Unknown reference.' )
    end
    
    % Re-references the EEG data to the median.
    trialEEG = bsxfun ( @minus, trialEEG, reference );
    
    % Saves the current trial EEG data.
    trials ( EEGchans, : ) = trialEEG;
end


% Silences the bad channels, if requested.
if ~isequal ( config.hide, false )
    
    % Gets the bad channels.
    badchan  = intersect ( trialdata.label, config.bad );
    badchan  = ismember  ( trialdata.label, badchan );
    
    switch config.hide
        case 'nan'
            trials ( badchan, : ) = NaN;
        case 'zeros'
            trials ( badchan, : ) = 0;
        otherwise
            error ( 'Unknown hiding method.' )
    end
end

% Saves the data.
trialdata.trial = mat2cell ( trials, size ( trials, 1 ), triallen );
