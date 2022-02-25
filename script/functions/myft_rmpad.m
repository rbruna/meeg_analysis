function data = myft_rmpad ( data, pad )

% Gets the number of trials.
ntrial = numel ( data.trial );

% Calculates the padding in samples.
pad    = pad * data.fsample;

% Checks if the padding is the same for all the trials.
if numel ( pad ) == 1
    pad    = repmat ( pad, ntrial, 1 );
end

% Goes through each trial.
for tindex = 1: ntrial
    
    % Gets the data for the current trial.
    tdata  = data.trial { tindex };
    ttime  = data.time  { tindex };
    
    % Removes the padding from the trial and the time vector.
    tdata  = tdata ( :, pad ( tindex ) + 1: end - pad ( tindex ) );
    ttime  = ttime ( pad ( tindex ) + 1: end - pad ( tindex ) );
    
    % Stores the data.
    data.trial { tindex } = tdata;
    data.time  { tindex } = ttime;
end

% If the sample information is present, removes the padding.
if isfield ( data, 'sampleinfo' )
    data.sampleinfo ( :, 1 ) = data.sampleinfo ( :, 1 ) + pad;
    data.sampleinfo ( :, 2 ) = data.sampleinfo ( :, 2 ) - pad;
end
