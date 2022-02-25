function event = myfiff_read_event ( filename, header )

% Gets the file header, if needed.
if nargin < 2
    header = myfiff_read_header ( filename );
end
info = header.orig;

% Gets the trigger channels.
FIFF    = fiff_define_constants;
channel = find ( [ info.chs.kind ] == FIFF.FIFFV_STIM_CH & [ info.chs.logno ] > 100 & [ info.chs.logno ] < 200 );

% Initializes the event structure.
event   = struct ( 'type', {}, 'sample', {}, 'value', {}, 'offset', {}, 'duration', {} );

% If no channels selected returns an empty event structure.
if isempty ( channel )
    return
end

% Loads the data of the trigger channels.
% rawinfo = fiff_setup_read_raw ( filename );
% rawdata = fiff_read_raw_segment ( rawinfo, 1, inf, channel );
rawdata = myfiff_read_raw ( filename, 1, inf, channel );


% Goes through each trigger channel.
for cindex = 1: numel ( channel )
    
    % Gets the channel label.
    chan    = channel ( cindex );
    type    = header.label { chan };
    
    % Gets the channel data.
    STI     = rawdata ( cindex, : );
    
    % Corrects the sign of the higher bit.
    STI ( STI <= -pow2 (14) ) = pow2 (16) + STI ( STI <= -pow2 (14) );
    STI     = int64 ( STI );
    
    % Splits the trigger channel in stimuli and responses.
    RES     = bitand ( STI, pow2 ( 16 ) - pow2 ( 12 ) );
    STI     = STI - RES;
    
    % Derivates the channel and gets the rising edge.
    dSTI    = diff ( STI );
    dRES    = diff ( RES );
    
    rSTI    = find ( dSTI > 0 );
    rRES    = find ( dRES > 0 );
    
    
    % Creates a event structure for the stimuli.
    sevent  = struct ( ...
        'type',     type, ...
        'sample',   num2cell ( rSTI ), ...
        'value',    num2cell ( dSTI ( rSTI ) ), ...
        'offset',   [], ...
        'duration', 0 );
    
    % Tries to find the duration of each stimuli.
    for eindex = 1: numel ( sevent )
        sevent ( eindex ).duration = find ( dSTI ( sevent ( eindex ).sample: end ) == -sevent ( eindex ).value, 1, 'first' ) - 1;
    end
    
    
    % Creates a event structure for the responses.
    revent  = struct ( ...
        'type',     type, ...
        'sample',   num2cell ( rRES ), ...
        'value',    num2cell ( dRES ( rRES ) ), ...
        'offset',   [], ...
        'duration', 0 );
    
    % Tries to find the duration of each responses.
    for eindex = 1: numel ( revent )
        revent ( eindex ).duration = find ( dRES ( revent ( eindex ).sample: end ) == -revent ( eindex ).value, 1, 'first' ) - 1;
    end
    
    % Joins the stimuli and the responeses.
    event   = cat ( 2, event, sevent, revent );
end

% Sorts the events by sample.
[ ~, sorting ] = sort ( [ event.sample ] );
event    = event ( sorting );
