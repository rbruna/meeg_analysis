function data = myft_appenddata ( cfg, varargin ) %#ok<INUSL>

% If no inputs rises an error.
if nargin == 1, error ( 'No input.' ); end

% If only one input returns it.
if nargin == 2
    data = varargin {1};
    return
end

% Gets the inputs.
datas  = varargin;

% Checks that all the inputs are raw data.
if ~all ( cellfun ( @israw, datas ) )
    error ( 'Invalida inputs.' );
end


% Gets the field names of each data structure.
fnames = cellfun ( @fieldnames, datas, 'UniformOutput', false );

% Keeps only the fields common to all the data structures.
fname  = fnames {1};
fname  = setdiff ( fname, { 'cfg' } );
for findex = 2: numel ( datas )
    fname = intersect ( fname, fnames { findex } );
end
for findex = 1: numel ( datas )
    datas { findex } = rmfield ( datas { findex }, setdiff ( fnames { findex }, fname ) );
end

% Joins the datas in an array of structure.
datas  = cat ( 1, datas {:} );


% Checks that all the sampling rates are similar.
if ismember ( 'fsample', fname ) && ~isequaln ( datas.fsample )
    error ( 'Sampling rates are different among data structures.' )
end


% Checks the grad and elec fields, if existent.
if ismember ( 'elec', fname ) && ~isequaln ( datas.elec )
    warning ( 'Electrode definitions are different among data structres.' )
    datas  = rmfield ( datas, 'elec' );
end
if ismember ( 'grad', fname ) && ~isequaln ( datas.grad )
    warning ( 'Gradiometer definitions are different among data structres.' )
    datas  = rmfield ( datas, 'grad' );
end


% Now decides if the data must be concatenated along trials or along time.
alongchans  = false;
alongtrials = false;


% If 'sampleinfos' are identical data must be concatenated along sensors.
if ismember ( 'sampleinfo', fname ) && isequaln ( datas.sampleinfo )
    
    % Marks the trials to concatenate along channels.
    alongchans = true;
end


% If all labels are equal data must be concatenated along trials.
if isequaln ( datas.label )
    alongtrials = true;
    
% If all labels are different data must be concatenated along channels.
elseif numel ( cat ( 1, ( datas.label ) ) ) == numel ( unique ( cat ( 1, ( datas.label ) ) ) )
    alongchans = true;
    
% Otherwise data must be checked.
else
    
    % Gets the list of repeated and unique labels.
    labels  = cat ( 1, ( datas.label ) );
    label   = unique ( labels );
    
    % Gets the times each sensor appears.
    orders  = my_matchstr ( unique ( labels ), labels );
%     appears = hist ( orders, 1: numel ( label ) );
    appears = histcounts ( orders, 'BinMethod', 'integers' );
    
    % Checks if data must be concatenated along sensors.
    if alongchans
        
        % Goes through eachs sensor.
        for sindex = 1: numel ( label )
            
            % If appears only once continues.
            if appears ( sindex ) == 1, continue, end
            
            % Equal sensors must contain equal data.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % To fix.
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            error ( 'Data contains inconsistent channels.' );
        end
        
    % Otherwise keeps only the channels common to all data structures.
    else
        
        % Gets only the list of channels present in all datas.
        label_ = label ( appears == numel ( datas ) );
        
        % If no commong channels rises an error.
        if ~numel ( label_ )
            error ( 'Data must be concatenated along trials, but there are not common channels.' );
        end
        
        % Sorts the channels according to first data.
        label_ = datas (1).label ( ismember ( datas (1).label, label_ ) );
        
        % Goes through each data structure.
        for dindex = 1: numel ( datas )
            
            % Gets the indexes of the channels to keep.
            orders = my_matchstr ( datas ( dindex ).label, label_ );
            
            % Keeps only the selected channels in the selected order.
            datas ( dindex ) = my_orderchans ( datas ( dindex ), orders );
        end
    end
end


% If data concatenation can not be determined rises an error.
if ~xor ( alongchans, alongtrials )
    error ( 'Can not determine how to concatenate the data structures.' )
end

% Concatenates along trials.
if alongtrials
    
    % Initializes the output data to the first input.
    data = datas (1);
    
    % Concatenates the trials.
    data.time  = cat ( 2, datas.time  );
    data.trial = cat ( 2, datas.trial );
    
    % Concatenates the trialinfos.
    if isfield ( datas, 'sampleinfo' )
        data.sampleinfo = cat ( 1, datas.sampleinfo );
    end
    
    % Concatenates the trialinfos.
    if isfield ( datas, 'trialinfo' )
        data.trialinfo = cat ( 1, datas.trialinfo );
    end
end

% Concatenates along trials.
if alongchans
    
    % Initializes the output data to the first input.
    data = datas (1);
    
    % Concatenates the sensor labels.
    data.label = cat ( 1, datas.label );
    
    % Gets the trial data.
    trials     = { datas.trial };
    
    % Concatenates the data for each trial.
    for tindex = 1: numel ( datas (1).trial )
        
        % Gets the data for the current trial
        trial = cellfun ( @(trials) trials ( tindex ), trials );
        
        % Joins the channels from all the datasets.
        data.trial { tindex } = cat ( 1, trial {:} );
    end
end


function output = israw ( input )

% The minimum fields are 'label', 'time' and 'trial'.
output = isfield ( input, { 'label', 'time', 'trial' } );

if ~output, return, end

% 'time' and 'trial' must be cells of the same lenght.
output = iscell ( input.time ) && iscell ( input.trial );

if ~output, return, end

% 'time' and 'trial' must be cells of the same lenght.
output = numel ( input.time ) == numel ( input.trial );
