function event = myeep_read_evt ( filename )

% Based on libeep 3.3.177 functions on:
% * libcnt/evt.c
% * libcnt/evt.h
% * v4/eep.c
% * v4/eep.h


% Opens the file to read.
fid = fopen ( filename, 'rb' );

% Reads the event header.
time     = fread ( fid, 3, '*uint32' ); %#ok<NASGU>
version  = fread ( fid, 1, '*int32' ); %#ok<NASGU>
compress = fread ( fid, 1, '*int32' ); %#ok<NASGU>
encrpyt  = fread ( fid, 1, '*int32' ); %#ok<NASGU>


% Gets the main class.
class    = myeepevt_read_class ( fid );
assert ( strcmp ( class, 'class dcEventsLibrary_c' ), 'Bad file.' );

% Reads the event library.
library  = myeepevt_read_library ( fid );


% Closes the file.
fclose ( fid );


% Sets the ouput.
event    = library.entries;



function library = myeepevt_read_library ( fid )

% Reads the library name.
name      = myeepevt_read_string ( fid );

% Reads the number of events.
nevent    = fread ( fid, 1, 'uint32' );

% Initializes the list of events.
events    = cell ( nevent, 1 );

% Goes through each event.
for eindex = 1: nevent
    
    % Reads the event class.
    class   = myeepevt_read_class ( fid );
    
    % Reads the event with the class-specific function.
    switch class
        case 'class dcEpochEvent_c'
            event    = myeepevt_read_epoch ( fid );
        case 'class dcEventMarker_c'
            event    = myeepevt_read_marker ( fid );
        case 'class dcArtefactEvent_c'
            event    = myeepevt_read_artefact ( fid );
        case 'class dcSpikeEvent_c'
            event    = myeepevt_read_spike ( fid );
        case 'class dcSeizureEvent_c'
            event    = myeepevt_read_seizure ( fid );
        case 'class dcSleepEvent_c'
            event    = myeepevt_read_sleep ( fid );
        case 'class dcRPeakEvent_c'
            event    = myeepevt_read_rpeak ( fid );
        otherwise
            error ( 'Unknown event class.' )
    end
    
    % Stores the current event.
    events { eindex } = event;
end

% Concatenates all the events.
events  = cat ( 1, events {:} );


% Sets the ouput.
library         = [];
library.name    = name;
library.entries = events;



function marker = myeepevt_read_epoch    ( fid )

% Reads the event.
event    = myeepevt_read_event ( fid );

% if version < 33
%   show_amplitude = fread ( fid, 1, '*int32' );
% end

% Sets the ouput.
marker                = [];
marker.class          = 'Epoch Event';
marker.event          = event;
marker.chaninfo       = [];
marker.description    = event.name;
marker.show_amplitude = [];
marker.show_duration  = [];



function marker = myeepevt_read_marker   ( fid )

% Reads the event.
event    = myeepevt_read_event ( fid );

% Reads the channel information.
chaninfo = myeepevt_read_chaninfo ( fid );

% Reads the marker description.
desc     = myeepevt_read_string ( fid );

% if version >= 35
%   if version >= 103
show_amplitude = fread ( fid, 1, '*int32' );
%   else
%     show_amplitude = fread ( fid, 1, '*int8' );
%   end
show_duration = fread ( fid, 1, '*int8' );
% end


% Sets the ouput.
marker                = [];
marker.class          = 'Event Marker';
marker.event          = event;
marker.chaninfo       = chaninfo;
marker.description    = desc;
marker.show_amplitude = show_amplitude;
marker.show_duration  = show_duration;



function marker = myeepevt_read_artefact ( fid ), error ( 'Not yet coded.' ); %#ok<INUSD,STOUT> See libcnt/evt.c#563
function marker = myeepevt_read_spike    ( fid ), error ( 'Not yet coded.' ); %#ok<INUSD,STOUT> See libcnt/evt.c#574
function marker = myeepevt_read_seizure  ( fid ), error ( 'Not yet coded.' ); %#ok<INUSD,STOUT> See libcnt/evt.c#581
function marker = myeepevt_read_sleep    ( fid ), error ( 'Not yet coded.' ); %#ok<INUSD,STOUT> See libcnt/evt.c#588
function marker = myeepevt_read_rpeak    ( fid ), error ( 'Not yet coded.' ); %#ok<INUSD,STOUT> See libcnt/evt.c#595



function event = myeepevt_read_event ( fid )

% Reads the event ID.
id = fread ( fid, 1, '*int32' );

% Reads the event GUID.
fread ( fid, 1, '*uint32' );
fread ( fid, 1, '*uint16' );
fread ( fid, 1, '*uint16' );
fread ( fid, 8, '*uint8' );


% Reads the event class.
class    = myeepevt_read_class ( fid );

% Reads the event name.
uname    = myeepevt_read_string ( fid );
name     = myeepevt_read_string ( fid );

% Reads the event type and state.
type     = fread ( fid, 1, '*int32' );
state    = fread ( fid, 1, '*int32' );

% Reads the original tag.
original = fread ( fid, 1, '*int8' );

% Reads the event duration.
duration = fread ( fid, 1, '*double' );
offset   = fread ( fid, 1, '*double' );

% Reads the timestamp.
time     = fread ( fid, 2, '*double' );
time     = time (1) * ( 60 * 60 * 24 ) - 2209161600 + time (2);

% Reads the epoch descriptors.
epoch    = myeepevt_read_epoch_descriptors ( fid );

icond    = strcmp ( { epoch.name }, 'Condition' );
if any ( icond )
    name     = epoch ( icond ).data;
    epoch ( icond ) = [];
end


% Sets the ouput.
event            = [];
event.id         = id;
event.class      = class;
event.uname      = uname;
event.name       = name;
event.type       = type;
event.state      = state;
event.original   = original;
event.duration   = duration;
event.offset     = offset;
event.time       = time;
event.epoch_desc = epoch;



function descs = myeepevt_read_epoch_descriptors ( fid )

% Gets the number of descriptors.
ndesc     = fread ( fid, 1, '*int32' );

% Initializes the list of descriptors.
descs     = cell ( ndesc, 1 );

% Goes through each descriptor.
for dindex = 1: ndesc
    
    % Gets the name of the descriptor.
    dname    = myeepevt_read_string ( fid );
    
    % Reads the data.
    ddata    = myeepevt_read_data ( fid );
    
    % Reads the descriptor unit.
    dunit    = myeepevt_read_string ( fid );
    
    % Stores the output.
    desc      = [];
    desc.name = dname;
    desc.data = ddata;
    desc.unit = dunit;

    descs { dindex } = desc;
end

% Concatenates all the epoch descriptors.
descs    = cat ( 1, descs {:} );



function chaninfo = myeepevt_read_chaninfo ( fid )

% Gets the active channel and the reference.
active   = myeepevt_read_string ( fid );
ref      = myeepevt_read_string ( fid );

% Sets the output.
chaninfo.active = active;
chaninfo.ref    = ref;




function class = myeepevt_read_class ( fid )

% Gets the class tag.
tag      = fread ( fid, 1, '*int32' );

% If no tag exits.
if tag == 0
    class    = '';
    return
end

% Checks the tag.
assert ( tag == -1, 'Unknown class tag.' );

% Reads the class name.
class    = myeepevt_read_string ( fid );



function string = myeepevt_read_string ( fid )

% Gets the length of the text.
length   = fread ( fid, 1, '*uint8' );
if length == 255
    error ( 'Text too long' );
%     length   = fread ( fid, 1, '*uint16' );
end

% Reads the text.
string   = fread ( fid, [ 1 length ], '*char' );



function string = myeepevt_read_unicode ( fid )

% Gets the length of the text.
length   = fread ( fid, 1, '*int32' );
if length == 255
    error ( 'Text too long' );
%     length   = fread ( fid, 1, '*uint16' );
end

% Reads the text.
string   = fread ( fid, [ 1 length ], '*uint8' );
string   = string ( 1: 2: end );
string   = cast ( string, 'char' );



function data = myeepevt_read_data ( fid )

% Gets the type of data.
datatype = fread ( fid, 1, '*int16' );

% Reads the data.
switch datatype
    case 0
    case 1
    case 2
        data     = fread ( fid, 1, '*int16' );
    case 3
        data     = fread ( fid, 1, '*int32' );
    case 4
        data     = fread ( fid, 1, '*single' );
    case 5
        data     = fread ( fid, 1, '*double' );
    case 8
        data     = myeepevt_read_unicode ( fid );
    case 11
        error ( 'Data type not supported.' );
    case pow2 (  9 )
        data     = myeepevt_read_array ( fid );
    case pow2 ( 10 )
    otherwise
        if bitand ( datatype, bitor ( pow2 ( 13 ), pow2 ( 14 ) ) )
            data     = myeepevt_read_array ( fid );
        else
            error ( 'Data type not supported.' );
        end
end



function data = myeepevt_read_array ( fid )

% Gets the type of data.
datatype = fread ( fid, 1, '*int16' );

% Reads a dummy element of the right size.
switch datatype
    case 4
        fread ( fid, 1, '*single' );
    otherwise
        error ( 'Data type not supported.' );
end

% Gets the length of the array.
datalen  = fread ( fid, 1, '*uint32' );

% Reads the data.
switch datatype
    case 4
        data     = fread ( fid, datalen, '*single' );
    otherwise
        error ( 'Data type not supported.' );
end
