function seginfo = myeep_read_seg ( filename )

% Checks the input.
if nargin < 1
    error ( 'No file provided.' );
end


% If no file returns an empty structure.
if ~exist ( filename, 'file' )
    seginfo  = struct ( ...
        'identifier',   {}, ...
        'start_time',   {}, ...
        'sample_count', {} );
    
    return
end

    


% Opens the file to read.
fid      = fopen ( filename, 'rb' );
rawseg   = fread ( fid, [ 1 inf ], '*char' );

% Closes the file.
fclose ( fid );


% Looks fo the segment definition.
hits     = regexp ( rawseg, 'NumberSegments=[\s]*([\d]+)(.*)', 'tokens' );
nseg     = str2double ( hits {1} {1} );
segdata  = strtrim ( hits {1} {2} );

% Parses the segment definition.
segdata  = textscan ( segdata, '%f %f %d', nseg - 1 );

% Converts the start date into POSIX time format.
segtime  = segdata {1} * ( 60 * 60 * 24 ) - 2209161600 + segdata {2};
seglen   = segdata {3};

% Generates a segment identifier.
segid    = ( 2: nseg )';


% Stores the segment information.
seginfo  = struct ( ...
    'identifier',   num2cell ( segid ), ...
    'start_time',   num2cell ( segtime ), ...
    'sample_count', num2cell ( seglen ) );
