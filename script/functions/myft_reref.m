function trialdata = myft_reref ( trialdata, refchan, badchan )


% Sets the default parameters.
if nargin < 2 || isempty ( refchan )
    refchan = 'EEG';
end

if nargin < 3
    badchan = {};
end



% Identifies the EEG channels.
eegchan = ft_channelselection ( 'EEG', trialdata.label );
eegind  = ismember ( trialdata.label, eegchan );

% If common average reference, checks the number of channels.
if strcmp ( refchan, 'EEG' ) && numel ( eegchan ) < 32
    warning ( 'Applying common average reference to less than 32 channels.' )
end


% Identifies the reference channels.
refchan = ft_channelselection ( refchan, trialdata.label );
refind  = ismember ( trialdata.label, refchan );


% Initilizes the mapper to the identity matrix.
mapper  = eye ( numel ( trialdata.label ) );

% Defines the reference operator.
eegref           = double ( refind (:)' ) / sum ( refind );

% Inclides the reference operator in the mapper.
mapper ( eegind, : ) = mapper ( eegind, : ) - eegref;


% Applies the re-referencing mapper to the data.
trialdata.trial = cellfun ( ...
    @(trial) mapper * trial, ...
    trialdata.trial, ...
    'UniformOutput', false );
