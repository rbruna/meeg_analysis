function event = mymff_read_event ( filename, header )

% Gets the file header, if needed.
if nargin < 2
    header     = mymmf_read_header ( filename );
end
xmlinfo    = header.orig.xml;


% Creates the event structure.
event      = struct ( 'type', {}, 'sample', {}, 'duration', {}, 'offset', {}, 'value', {} );

% If no events definition exits.
if ~isfield ( xmlinfo, 'eventTrack' )
    return
end


% Calculates the beginning of the epoch.
epochdate  = xmlinfo.fileInfo.recordTime {1};
epochstamp = mymff_time2unix ( epochdate );


% Looks for event definitions.
rawevent   = xmlinfo.eventTrack;

% Gets the label for each file.
eventtype  = {};
for findex = 1: numel ( rawevent )
    eventtype  = cat ( 2, eventtype, repmat ( rawevent ( findex ).name, 1, numel ( rawevent ( findex ).event ) ) );
end

% Concatenates the events in all the files.
eventinfo  = [ rawevent.event ];
nevent     = numel ( eventinfo );

event ( nevent ).value = [];

for eindex = 1: nevent
    
    % Gets the event information.
    eventdate  = eventinfo ( eindex ).beginTime {1};
    eventstamp = mymff_time2unix ( eventdate );
    eventlen   = eventinfo ( eindex ).duration {1};
    eventlen   = str2double ( eventlen ) / 1e9;
    eventval   = eventinfo ( eindex ).code {1};
    
    % Stores the events in FieldTrip format.
    event ( eindex ).type     = eventtype { eindex };
    event ( eindex ).sample   = round ( ( eventstamp - epochstamp ) * header.Fs ) + 1;
    event ( eindex ).duration = eventlen * header.Fs;
    event ( eindex ).offset   = 0;
    event ( eindex ).value    = eventval;
end
