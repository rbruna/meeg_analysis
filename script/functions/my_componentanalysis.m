function compdata = my_componentanalysis ( cfg, trialdata )


% Checks the input.
if ~isfield ( cfg, 'topolabel' )
    error ( 'No labels provided for the topography channels.' );
end
if ~isfield ( cfg, 'unmixing' )
    error ( 'No unmixing matrix provided.' );
end

% Gets the metadata.
nchan               = numel ( cfg.topolabel );
ncomp               = size  ( cfg.unmixing, 2 );
ntrial              = numel ( trialdata.trial );

% Checks that the provided data and configuration are compatible.
if size ( cfg.unmixing, 1 ) ~= nchan
    error ( 'The mixing matrix and the topography do not have the same number of channels.' );
end
if size ( cfg.unmixing, 2 ) ~= size ( cfg.mixing, 1 ) || size ( cfg.unmixing, 1 ) ~= size ( cfg.mixing, 2 )
    error ( 'The mixing and unmixing matrices are not compatible.' )
end
if ~all ( ismember ( cfg.topolabel, trialdata.label ) )
    error ( 'Not all the channels present in the topography are present in the data.' )
end


% Initializes the output structure.
compdata            = [];
compdata.label      = cellfun ( @(x) sprintf ( 'component%03d', x ), num2cell ( 1: ncomp )', 'UniformOutput', false );
compdata.trial      = cell ( size ( trialdata.time ) );
compdata.time       = trialdata.time;
compdata.fsample    = trialdata.fsample;

if isfield ( trialdata, 'sampleinfo' )
    compdata.sampleinfo = trialdata.sampleinfo;
end
if isfield ( trialdata, 'grad' )
    compdata.grad       = trialdata.grad;
end
if isfield ( trialdata, 'elec' )
    compdata.elec       = trialdata.elec;
end

compdata.topolabel  = cfg.topolabel;
compdata.topo       = cfg.mixing;
compdata.unmixing   = cfg.unmixing;


% Gets the indexes of the channels provided in the topography.
chan = my_matchstr ( trialdata.label, cfg.topolabel );

% Goes through each trial.
for tindex = 1: ntrial
    
    % Gets the current trial data for the selected channels.
    chanraw = trialdata.trial { tindex } ( chan, : );
    
    % Calcualtes the components and stores them.
    compdata.trial { tindex } = cfg.unmixing * chanraw;
end
