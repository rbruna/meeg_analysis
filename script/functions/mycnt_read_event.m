function event = mycnt_read_event ( filename, varargin )

% Based on EEGlab functions:
% * loadcnt by Sean Fitzgibbon, Arnaud Delorme
% * load_scan41


header = find ( strcmp ( varargin, 'header' ), 1, 'last' );

if ~isempty ( header ) && header < numel ( varargin )
    header = varargin { header + 1 };
else
    header = mycnt_read_header ( filename );
end


% Gets the CNT header and the raw event structure.
filedata = header.orig;
rawevent = filedata.event;

% Splits the events in stimulous and responeses.
rawstims = rawevent ( [ filedata.event.stimtype ] ~= 0 );
rawresps = rawevent ( [ filedata.event.keypad_accept ] ~= 0 );

% Builds FieldTrip event structures for the stimulous and responses.
stims    = struct ( ...
    'type',     'stimtype', ...
    'sample',   num2cell ( [ rawstims.offset ] + 1 ), ...
    'value',    { rawstims.stimtype }, ...
    'offset',   0, ...
    'duration', 0 );

resps    = struct ( ...
    'type',     'keypad_accept', ...
    'sample',   num2cell ( [ rawresps.offset ] + 1 ), ...
    'value',    { rawresps.keypad_accept }, ...
    'offset',   0, ...
    'duration', 0 );

% Merges and sorts the events.
event    = cat ( 1, stims, resps );
[ ~, o ] = sort ( [ event.sample ] );
event    = event ( o );
