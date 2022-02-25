function data = mycnt_read_data ( filename, varargin )

% Based on EEGlab functions:
% * loadcnt by Sean Fitzgibbon, Arnaud Delorme
% * load_scan41

header  = find ( strcmp ( varargin, 'header'  ), 1, 'last' );
scale   = find ( strcmp ( varargin, 'scale'   ), 1, 'last' );
sbeg    = find ( strcmp ( varargin, 'sbeg'    ), 1, 'last' );
send    = find ( strcmp ( varargin, 'send'    ), 1, 'last' );
channel = find ( strcmp ( varargin, 'channel' ), 1, 'last' );


if ~isempty ( header ) && header < numel ( varargin )
    header  = varargin { header + 1 };
else
    header  = mycnt_read_header ( filename );
end

if ~isempty ( scale ) && scale < numel ( varargin )
    scale   = varargin { scale + 1 };
else
    scale   = true;
end

if ~isempty ( sbeg ) && sbeg < numel ( varargin )
    sbeg    = varargin { sbeg + 1 };
else
    sbeg    = 1;
end

if ~isempty ( send ) && send < numel ( varargin )
    send    = varargin { send + 1 };
else
    send    = inf;
end

if ~isempty ( channel ) && channel < numel ( varargin )
    channel = varargin { channel + 1 };
else
    channel = [];
end

% Gets the CNT header and the raw event structure.
filedata = header.orig;


% Opens the file to read.
fid = fopen ( filename, 'r', 'ieee-le' );

% Escapes the header.
fseek ( fid, 900, 'cof' );

% Escapes the channel definition.
fseek ( fid, 75 * filedata.header.nchannels, 'cof' );

% Stores the current position as the beginning of the data.
dbeg = ftell ( fid );

% Gets the position of the end of the data.
dend = filedata.header.eventtablepos;

if ~dend
    fseek ( fid, 0, 'eof' );
    dend = ftell ( fid );
end

% Calculates the bit depth.
bdepth = ( dend - dbeg ) / ( filedata.header.nchannels * filedata.header.numsamples );
format = sprintf ( 'int%2i', bdepth * 8 );

% Corrects the end of the data of interest, if needed.
if send > header.orig.header.numsamples
    send = header.orig.header.numsamples;
end

% Calculates the length of the data of interest.
slen = send - sbeg + 1;


% Calculates the shift to the data of interest.
pbeg = ( sbeg - 1 ) * bdepth * filedata.header.nchannels;

% Jumps to the beginning of the data of interest.
fseek ( fid, dbeg, 'bof' );
fseek ( fid, pbeg, 'cof' );

% Reads the data.
data = fread ( fid, [ filedata.header.nchannels slen ], format );

% Closes the file.
fclose ( fid );


% Scales the data, if requested.
if scale
    
    % Gets the baseline and the scaling factor.
    baseline = [ filedata.electloc.baseline ]';
    sensit   = [ filedata.electloc.sensitivity ]';
    calib    = [ filedata.electloc.calib ]';
    
    % Removes the baseline and scales the data.
    data     = bsxfun ( @minus, data, baseline );
    data     = bsxfun ( @times, data, sensit .* calib / 204.8 );
end

% Selects a subset of channels, if requested.
if ~isempty ( channel )
    data     = data ( channel, : );
end
