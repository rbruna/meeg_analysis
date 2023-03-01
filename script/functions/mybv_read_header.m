function header = mybv_read_header ( filename )

% Based on FieldTrip 20190705 functions:
% * read_brainvision_vhdr by Robert Oostenveld.


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


% Initializes the channels cell array.
chans  = cell ( lines, 1 );

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
    
    
    % Checks if we are in the common info section.
    if strcmpi ( slabel, 'Common Infos' )
        
        % Interprets the line.
        ctext = regexp ( ltext, '^([^=]+)=(.*)$', 'tokens' );
        
        if isempty ( ctext )
            warning ( 'Ignoring incomplete/erroneous information.' )
            continue
        end
        
        % Stores the information.
        info.( ctext {1} {1} ) = ctext {1} {2};
    end
    
    % Checks if we are in the binary info section.
    if strcmpi ( slabel, 'Binary Infos' )
        
        % Interprets the line.
        ctext = regexp ( ltext, '^([^=]+)=(.*)$', 'tokens' );
        
        if isempty ( ctext )
            warning ( 'Ignoring incomplete/erroneous information.' )
            continue
        end
        
        % Stores the information.
        info.( ctext {1} {1} ) = ctext {1} {2};
    end
    
    % Checks if we are on the channel info section.
    if strcmpi ( slabel, 'Channel Infos' )
        
        % Interprets the line.
        ctext = regexp ( ltext, '^Ch[0-9]+=([^,]+),([^,]*),([0-9\.]*)(?,([^,]+))?', 'tokens' );
        
        if isempty ( ctext )
            warning ( 'Ignoring incomplete/erroneous channel.' )
            continue
        end
        
        % Fills the channel.
        chan            = [];
        chan.name       = ctext {1} {1};
        chan.reference  = ctext {1} {2};
        chan.resolution = str2double ( ctext {1} {3} );
        chan.units      = ctext {1} {4};
        
        % If no resolution defined, sets it to 1.
        if ~isfinite ( chan.resolution )
            chan.resolution = 1;
        end
        
        % Fills the units with the standard.
        if isempty ( chan.units )
            chan.units      = 'uV';
        end
        
        % Replaces the "\1" strings by commas.
        chan.name       = strrep ( chan.name, '\1', ',' );
        chan.reference  = strrep ( chan.reference, '\1', ',' );
        
        % Replaces the "mu" in "microVolts" (UTF-8 0xCE 0xBC) to "u".
        if strcmpi ( enc, 'utf-8' )
            chan.units      = strrep ( chan.units, native2unicode ( [ 194 181 ] ), 'u' );
            chan.units      = strrep ( chan.units, native2unicode ( [ 181 ] ), 'u' );
        end
        
        % Stores the channel information.
        chans { lindex } = chan;
    end
    
    % Checks if we are on the comments section.
    if strcmpi ( slabel, 'Comment' )
        
        % Interprets the line.
        ctext = regexp ( ltext, '^([^=]+)=(.*)$', 'tokens' );
        
        if isempty ( ctext )
            continue
        end
        
        % Gets the left and right sides of the definition.
        lside = strtrim ( ctext {1} {1} );
        rside = strtrim ( ctext {1} {2} );
        
        % Checks if the comment indicates the reference.
        if strcmpi ( lside, 'Reference Channel Name' )
            info.ref_label = rside;
        end
        if strcmpi ( lside, 'Reference Phys. Chn.' )
            info.ref_index = str2double ( rside );
        end
    end
end

% Closes the file.
fclose ( fid );


% Rewrites the channels as a structure.
chans = cat ( 1, chans {:} );
nchan = numel ( chans );


% Lists the fields in the header information.
fields = fieldnames ( info );

% Converts the required values to numbers.
if any ( strcmpi ( fields, 'numberofchannels' ) )
    fname = fields { strcmpi ( fields, 'numberofchannels' ) };
    info.( fname ) = str2double ( info.( fname ) );
end
if any ( strcmpi ( fields, 'samplinginterval' ) )
    fname = fields { strcmpi ( fields, 'samplinginterval' ) };
    info.( fname ) = str2double ( info.( fname ) );
    info.Fs = 1e6 / info.( fname );
end

% Checks the integrity of the information.
if ~any ( strcmpi ( fields, 'datafile' ) )
    error ( 'No information of the data file.' )
end
if ~any ( strcmpi ( fields, 'dataformat' ) )
    error ( 'No information of the data format.' )
else
    fname = fields { strcmpi ( fields, 'numberofchannels' ) };
    if strcmpi ( info.( fname ), 'binary' ) && ~any ( strcmpi ( fields, 'binaryformat' ) )
        error ( 'No information of the binary data format.' )
    end
end
if ~any ( strcmpi ( fields, 'dataorientation' ) )
    error ( 'No information of the data orientation.' )
end
if ~any ( strcmpi ( fields, 'samplinginterval' ) )
    error ( 'No information on the sampling rate.' );
end
if ~any ( strcmpi ( fields, 'numberofchannels' ) )
    warning ( 'Adding number of channels from the channel description.' )
else
    fname = fields { strcmpi ( fields, 'numberofchannels' ) };
    if info.( fname ) ~= nchan
        error ( 'Inconsistent number of channels.' )
    end
end


% Gets the path to the data file (eeg file).
filepath = fileparts ( filename );
if ( isempty ( filepath ) ), filepath = '.'; end
datafile = sprintf ( '%s/%s', filepath, info.DataFile );

% For binary files.
if strcmpi ( info.DataFormat, 'Binary' )
    
    % Gets the sample size.
    switch lower ( info.BinaryFormat )
        case 'int_16'
            ssize = 2;
        case 'int_32'
            ssize = 4;
        case 'ieee_float_32'
            ssize = 4;
        otherwise
            error ( 'Unknown data format.' )
    end
    
    % Gets the size of the file, in bytes.
    datainfo = dir ( datafile );
    datasize = datainfo.bytes;
    
    % Calculates the number of samples.
    info.nSamples    = datasize / nchan / ssize;
    info.nTrials     = 1;
    info.nSamplesPre = 0;
    
% For text files.
elseif strcmpi ( info.DataFormat, 'ASCII' )
    
    error ( 'Not yet implemented.' );
    
else
    error ( 'Unknown data format.' );
end


% If the reference is a channel, includes it in the channel definition.
if isfield ( info, 'ref_label' ) && isfield ( info, 'ref_index' )
    
    warning ( 'Including the reference as a virtual channel.' )
    
    % Creates a virtual channel.
    chans = chans ( [ 1: info.ref_index info.ref_index: end ] );
    
    % Fills the channel information.
    chans ( info.ref_index ).name       = info.ref_label;
    chans ( info.ref_index ).reference  = '';
    chans ( info.ref_index ).resolution = 1;
    chans ( info.ref_index ).units      = 'V';
end

% Adds the channels information.
info.channels   = chans;
info.label      = { chans.name }';
info.reference  = { chans.reference }';
info.resolution = cat ( 1, chans.resolution );
info.chanunit   = { chans.units }';

% Converts the data to IS units (Volts).
nchan           = numel ( info.label );
newunit         = repmat ( { 'V' }, nchan, 1 );
scale           = ft_scalingfactor ( info.chanunit, newunit );
info.resolution = info.resolution .* scale;
info.chanunit   = newunit;
info.chantype   = repmat ( { 'eeg' }, nchan, 1 );


% Builds the FieldTrip header.
header             = [];
header.orig        = info;
header.Fs          = info.Fs;
header.label       = info.label;
header.nChans      = numel ( chans );
header.nSamples    = info.nSamples;
header.nSamplesPre = info.nSamplesPre;
header.nTrials     = info.nTrials;
header.chantype    = info.chantype;
header.chanunit    = info.chanunit;
