function event = myeep_read_event ( filename, rawinfo )

% Tries to get the header, if provided.
if nargin > 1
    if isfield ( rawinfo, 'orig' )
        rawinfo   = rawinfo.orig;
    end
else
    % Otherwise gets the EEProbe header from the file.
    rawinfo   = myeep_read_info ( filename );
end


% Gets the information from the system-specific header.
marker    = rawinfo.events;
rawevent  = cat ( 1, marker.event );


% Gets the segments start time.
sstart    = cat ( 2, rawinfo.segments.start_time );

% Gets the events start time.
estart    = cat ( 1, rawevent.time );

% Calculates the delays respect to each segment.
delay     = estart - sstart;
delay ( delay < 0 & delay > -1 ) = 0;

% Keeps the delay respect to the right segment.
delay ( delay < 0 ) = inf;
[ delay, sindex ] = min ( delay, [], 2 );

% Calculates the sample delay respect to the segment.
sdelay    = floor ( delay * rawinfo.sample_rate ) + 1;

% Calculates the sample offset respect to the beginning.
sdelay    = sdelay + double ( cat ( 1, rawinfo.segments ( sindex ).start_sample ) ) - 1;

% Calculates the event offset and duration in samples.
soffset   = round ( [ rawevent.offset ]' * rawinfo.sample_rate );
sduration = round ( [ rawevent.duration ]' * rawinfo.sample_rate );


% Sets the trigger value to 0.
svalue    = zeros ( numel ( marker ), 1 );

% Adds the value of the real triggers (Epoch events), if any.
hits      = strcmp ( { marker.class }, 'Epoch Event' );
if any ( hits )
    dummy     = cat ( 1, marker ( hits ).event );
    dummy     = cat ( 1, dummy.epoch_desc );
    value     = cat ( 1, dummy.data );
    svalue ( hits ) = value;
end



% Creates the Fieldtrip event structure.
event    = struct ( ...
    'type',        { rawevent.uname }', ...
    'sample',      num2cell ( sdelay ), ...
    'value',       num2cell ( svalue ), ...
    'offset',      num2cell ( soffset ), ...
    'duration',    num2cell ( sduration ), ...
    'timestamp',   { rawevent.time }', ...
    'rawdata',     { rawevent.epoch_desc }', ...
    'description', { marker.description }' );

% Adds the beginning of the segments.
sevent   = struct ( ...
    'type',        'Segment', ...
    'sample',      { rawinfo.segments.start_sample }', ...
    'value',       0, ...
    'offset',      0, ...
    'duration',    { rawinfo.segments.sample_count }', ...
    'timestamp',   { rawinfo.segments.start_time }', ...
    'rawdata',     [], ...
    'description', 'New segment' );
event    = cat ( 1, sevent, event );

% Sorts the events.
[ ~, order ] = sort ( [ event.sample ] );
event    = event ( order );
