function events = mybv_read_event ( filename, header )

% Reads the file header, if not provided.
if nargin < 2
    header = mybv_read_header ( filename );
end

% If no event file (vmrk) returns.
if ~isfield ( header.orig, 'MarkerFile' ) || isempty ( header.orig.MarkerFile )
    events = [];
    return
end

% Gets the path to the event file (vmrk file).
filepath = fileparts ( filename );
filename = sprintf ( '%s/%s', filepath, header.orig.MarkerFile );


% Opens the file to read.
fid    = fopen ( filename, 'rt', 'ieee-le', 'utf-8' );

% Initializes the encoding.
enc    = 'ascii';

% Reads the file to find the encoding format.
while ~feof ( fid )
    ltext  = fgetl ( fid );
    if strncmpi ( ltext, 'Codepage', 8 )
        enc    = strtrim ( ltext ( 10: end ) );
        break
    end
end

% Re-opens the file with the new encoding, if required.
if ~strcmpi ( enc, 'utf-8' )
    fclose ( fid );
    fid    = fopen ( filename, 'rt', 'ieee-le', enc );
end

% Goes back to the beginning of the file.
fseek ( fid, 0, 'bof' );

% Counts the lines.
lines  = 0;
while ~feof ( fid )
    fgetl ( fid );
    lines  = lines + 1;
end

% Goes back to the beginning of the file.
fseek ( fid, 0, 'bof' );


% Initializes the events cell array.
events = cell ( lines, 1 );

% Initializes the section label.
slabel = NaN;

% Reads the file line by line.
for lindex = 1: lines
    
    % Reads the current line.
    ltext  = fgetl ( fid );
    
    % If the line is empty or a comment, ignores it.
    if isempty ( ltext ) || strncmp ( ltext, ';', 1 )
        continue
    end
    
    % Checks if the line defines a new section.
    stext  = regexp ( ltext, '^\[(.*)\]$', 'tokens' );
    
    % If new section, changes the label and goes to the next line.
    if ~isempty ( stext )
        slabel = stext {1} {1};
        continue
    end
    
    
    % Checks if we are on the marker definition section.
    if strcmpi ( slabel, 'Marker Infos' )
        
        % Interprets the line.
        etext  = regexp ( ltext, '^Mk[0-9]+=([^,]+),([^,]*),([0-9]+),([0-9]+),([0-9]+)', 'tokens' );
        
        if isempty ( etext )
            warning ( 'Ignoring incomplete/erroneous marker.' )
            continue
        end
        
        % Fills the event.
        event           = [];
        event.type      = etext {1} {1};
        event.sample    = str2double ( etext {1} {3} );
        event.value     = etext {1} {2};
        event.offset    = [];
        event.duration  = str2double ( etext {1} {4} );
        event.timestamp = [];
        
        % Replaces the "\1" strings by commas.
        event.type      = strrep ( event.type, '\1', ',' );
        event.value     = strrep ( event.value, '\1', ',' );
        
        % Replaces triggers "S #" by the stimulus number.
        if strcmpi ( event.type, 'Stimulus' ) && strncmpi ( event.value, 'S', 1 ) && isfinite ( str2double ( event.value ( 2: end ) ) )
            event.value     = str2double ( event.value ( 2: end ) );
        end
        
        % Replaces triggers "R #" by the response number.
        if strcmpi ( event.type, 'Response' ) && strncmpi ( event.value, 'R', 1 ) && isfinite ( str2double ( event.value ( 2: end ) ) )
            event.value     = str2double ( event.value ( 2: end ) );
        end
        
        % Stores the event.
        events { lindex } = event;
    end
end

% Closes the file.
fclose ( fid );


% Rewrites the events as a structure.
events = cat ( 1, events {:} );

% % Only the stimulus and responses are returned here.
% events = events ( ismember ( { events.type }, { 'Stimulus' 'Response' } ) );
