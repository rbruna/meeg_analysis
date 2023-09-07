function header = mybdf_read_header ( filename )

% Based on specifications in:
% * https://www.edfplus.info/specs/edf.html
% * https://www.edfplus.info/specs/edfplus.html
%
% Based on functions:
% * read_biosemi_bdf by Robert Oostenveld.
% * openbdf (from EEGLAB).

% The BDF header is an EDF header with minor modifications.


% Opens the file to read.
fid = fopen ( filename, 'rb', 'ieee-le' );


% Reads the file version.
EDF         = [];
EDF.version = fread ( fid , [  1  8 ], '*char' );

% The version must be BIOSEMI to use this code.
if ~strcmp ( EDF.version ( 2: end ), 'BIOSEMI' )
    
    % Closes the file.
    fclose ( fid );
    
    % Raises an error.
    error ( 'This is not a BDF file.' )
end


% Reads the recording identifiers.
EDF.patient   = fread ( fid , [ 80  1 ], '*char' )';
EDF.recording = fread ( fid , [ 80  1 ], '*char' )';

% Reads the acquisition time.
EDF.date      = fread ( fid , [  8  1 ], '*char' )';
EDF.time      = fread ( fid , [  8  1 ], '*char' )';

% Reads the header metadata.
EDF.hdrlen    = fread ( fid , [  8  1 ], '*char' )';

% Reads the reserved field (data format?).
EDF.reserved  = fread ( fid , [ 44  1 ], '*char' )';

% Reads the information of the data records and signals (channels).
EDF.nrecord   = fread ( fid , [  8  1 ], '*char' )';
EDF.duration  = fread ( fid , [  8  1 ], '*char' )';
EDF.nchannel  = fread ( fid , [  4  1 ], '*char' )';

% Fixes the numeric values and trims the strings.
EDF.patient   = strtrim ( EDF.patient );
EDF.recording = strtrim ( EDF.recording );
EDF.reserved  = strtrim ( EDF.reserved );
EDF.hdrlen    = str2double ( EDF.hdrlen );
EDF.nrecord   = str2double ( EDF.nrecord );
EDF.duration  = str2double ( EDF.duration );
EDF.nchannel  = str2double ( EDF.nchannel );

% Reads the channels information.
chlabel   = fread ( fid , [ 16 EDF.nchannel ], '*char' )';
chtype    = fread ( fid , [ 80 EDF.nchannel ], '*char' )';
chunit    = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chphysmin = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chphysmax = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chdigmin  = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chdigmax  = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chfilter  = fread ( fid , [ 80 EDF.nchannel ], '*char' )';
chsamples = fread ( fid , [  8 EDF.nchannel ], '*char' )';
chextra   = fread ( fid , [ 32 EDF.nchannel ], '*char' )';

% Closes the file.
fclose ( fid );


% Rebuilds the text information as cell arrays.
chlabel   = num2cell ( chlabel, 2 );
chtype    = num2cell ( chtype, 2 );
chunit    = num2cell ( chunit, 2 );
chfilter  = num2cell ( chfilter, 2 );
chextra   = num2cell ( chextra, 2 );

% Covnerts the numeric values.
chphysmin = str2num ( chphysmin ); %#ok<ST2NM>
chphysmax = str2num ( chphysmax ); %#ok<ST2NM>
chdigmin  = str2num ( chdigmin ); %#ok<ST2NM>
chdigmax  = str2num ( chdigmax ); %#ok<ST2NM>
chsamples = str2num ( chsamples ); %#ok<ST2NM>

% Trims the strings.
chlabel   = cellfun ( @strtrim, chlabel,  'UniformOutput', false );
chtype    = cellfun ( @strtrim, chtype,   'UniformOutput', false );
chunit    = cellfun ( @strtrim, chunit,   'UniformOutput', false );
chfilter  = cellfun ( @strtrim, chfilter, 'UniformOutput', false );
chextra   = cellfun ( @strtrim, chextra,  'UniformOutput', false );


% Defines the per-channel calibration and offset.
chcalib   = ( chphysmax - chphysmin ) ./ ( chdigmax - chdigmin );
choffset  = chphysmin - chcalib .* chdigmin;

% Defines the per-channel sample rate.
chsrate   = chsamples / EDF.duration;


% Converts the units to SI units, if required.
hits      = strcmp ( chunit, 'uV' );
chunit   ( hits ) = { 'V' };
chcalib  ( hits ) = chcalib  ( hits ) ./ 1e6;
choffset ( hits ) = choffset ( hits ) ./ 1e6;


% Creates the channel structure.
EDF.channels  = struct ( ...
    'label',   chlabel, ...
    'type',    chtype, ...
    'physdim', chunit, ...
    'physmin', num2cell ( chphysmin ), ...
    'physmax', num2cell ( chphysmax ), ...
    'digmin',  num2cell ( chdigmin ), ...
    'digmax',  num2cell ( chdigmax ), ...
    'calib',   num2cell ( chcalib ), ...
    'offset',  num2cell ( choffset ), ...
    'filter',  chfilter, ...
    'samples', num2cell ( chsamples ), ...
    'srate',   num2cell ( chsrate ), ...
    'extra',   chextra );


% If not provided, tries to find out the data size.
if EDF.nrecord == -1
    
    % Raises a warning.
    warning ( 'Estimating the data length from the file size.' )
    
    % Opens the file to read.
    fid = fopen ( filename, 'rb', 'ieee-le' );
    
    % Goes to the end of the file.
    fseek ( fid , 0, 'eof');
    endpos = ftell ( fid );
    
    % Closes the file.
    fclose ( fid );
    
    % Gets the length of the data.
    EDF.nrecord = floor ( ( endpos - EDF.hdrlen ) / ( sum ( [ EDF.channels.samples ] ) * 2 ) );
end


% Checks that all the channels have the same sampling rate.
if any ( [ EDF.channels.samples ] ~= EDF.channels (1).samples )
    error ( 'This code cannot handle files with different sampling rate per channel.' );
end


% Checks the consistency of the data.
if any ( [ EDF.channels.digmin ] >= [ EDF.channels.digmax ] )
    warning ( 'Digital minimum larger than digital maximum.\n' );
end
if any ( [ EDF.channels.physmin ] >= [ EDF.channels.physmax ] )
    warning ( 'Digital minimum larger than digital maximum.\n' );
    
    % Uses the digital values.
    [ EDF.channels.physmin ] = my_deal ( [ EDF.channels.digmin ] );
    [ EDF.channels.physmax ] = my_deal ( [ EDF.channels.digmax ] );
end


% Generates the FieldTrip header.
header.orig        = EDF;
header.Fs          = EDF.channels (1).srate;
header.nChans      = EDF.nchannel;
header.label       = { EDF.channels.label };
header.nTrials     = 1;
header.nSamples    = round ( EDF.nrecord * EDF.duration * header.Fs );
header.nSamplesPre = 0;
