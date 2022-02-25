function cleandata = my_rejectcomponent ( cfg, compdata, trialdata )


% Checks the input.
if ~isfield ( compdata, 'topolabel' )
    error ( 'No labels provided for the topography channels.' );
end
if ~isfield ( compdata, 'topo' )
    error ( 'No mixing matrix provided.' );
end


% Gets the metadata.
nchan               = numel ( compdata.topolabel );
ntrial              = numel ( trialdata.trial );

% Checks that the provided data and configuration are compatible.
if nargin > 2 && ~all ( ismember ( compdata.topolabel, trialdata.label ) )
    error ( 'Not all the channels present in the topography are present in the data.' )
end


% Initializes the output structure.
if nargin > 2
    cleandata = trialdata;
else
    cleandata            = [];
    cleandata.label      = compdata.topolabel;
    cleandata.trial      = cell ( size ( compdata.time ) );
    cleandata.time       = compdata.time;
    cleandata.fsample    = compdata.fsample;
    
    if isfield ( compdata, 'sampleinfo' )
        cleandata.sampleinfo = compdata.sampleinfo;
    end
    if isfield ( compdata, 'grad' )
        cleandata.grad       = compdata.grad;
    end
    if isfield ( compdata, 'elec' )
        cleandata.elec       = compdata.elec;
    end
end


% Gets the indexes of the channels provided in the topography.
chan = my_matchstr ( trialdata.label, compdata.topolabel );

% Goes through each trial.
for tindex = 1: ntrial
    
    % Gets the current trial data for the selected channels.
    chanraw = trialdata.trial { tindex };
    
    % Gets the current component data.
    compraw = compdata.trial { tindex };
    
    % Remvevs the selected components.
    compraw ( cfg.component, : ) = 0;
    
    % Modifies the channels present in the topography.
    chanraw ( chan, : ) = compdata.topo * compraw;
    
    % Stores the new channel data.
    cleandata.trial { tindex } = chanraw;
end
