function sensor = mymff_read_sens ( filename, header )


% Gets the file header, if needed.
if nargin < 2 || isempty ( header )
    header       = mymff_read_header ( filename );
end
info         = header.orig;


% Gets the sensor information.
sensinfo     = info.xml.sensorLayout.sensors.sensor;
senslayout   = info.xml.coordinates.sensorLayout.sensors.sensor;

% Takes only the EEG (type 0) and reference (type 1) channels.
sensinfo     = sensinfo    ( ismember ( str2double ( [ sensinfo.type   ] ), [ 0 1 ] ) );
senslayout   = senslayout  ( ismember ( str2double ( [ senslayout.type ] ), [ 0 1 ] ) );

% Gets the channel type.
senstype     = [ sensinfo.type ]';
senstype     = str2double ( senstype );

% Gets the channel number.
sensnumber   = [ sensinfo.number ]';
sensnumber   = str2double ( sensnumber );

% Gets the channel names.
sensname     = [ sensinfo.name ]';
emptyname    = cellfun ( @isempty, sensname );

% Gets the default channel position.
senspos_x    = [ senslayout.x ]';
senspos_y    = [ senslayout.y ]';
senspos_z    = [ senslayout.z ]';
senspos      = [ senspos_x senspos_y senspos_z ];
senspos      = str2double ( senspos );

% Creates a channel name, if none provided.
if any ( emptyname & senstype == 0 )
    sensname ( emptyname & senstype == 0 ) = strcat ( 'EEG', cat ( 1, sensinfo ( emptyname & senstype == 0 ).number ) );
end
if any ( emptyname & senstype == 1 )
    sensname ( emptyname & senstype == 1 ) = strcat ( 'REF', cat ( 1, sensinfo ( emptyname & senstype == 1 ).number ) );
end

% Rewrites the names in Neuromag format.
sensname ( emptyname & senstype == 0 ) = regexprep ( sensname ( emptyname & senstype == 0 ), '^EEG(\d)$'   , 'EEG00$1' );
sensname ( emptyname & senstype == 0 ) = regexprep ( sensname ( emptyname & senstype == 0 ), '^EEG(\d{2})$', 'EEG0$1'  );

% Checks for calibration information.
if isfield ( info.xml.dataInfo (1).calibrations, 'calibration' )
    
    % Gets the signal calibration information.
    calinfo      = info.xml.dataInfo (1).calibrations.calibration;
    
    % Checks for the number of calibration factors.
    if numel ( calinfo.channels.ch ) ~= numel ( sensinfo )
        error ( 'Calibration coefficents does not match number of EEG channels.' )
    end
    
    % Gets the channel calibration.
    senscal      = str2double ( [ calinfo.channels.ch ]' );
else
    
    % Sets the calibration to 1.
    senscal      = ones ( size ( sensnumber ) );
end


% Sets the formatted channel information.
channame     = sensname ( senstype == 0 );
chanpos      = senspos  ( senstype == 0, : );
chancal      = senscal  ( senstype == 0 );
senstra      = zeros ( size ( chanpos, 1 ), size ( senspos, 1 ) );
senstra ( :, senstype == 0 ) = eye ( size ( chanpos, 1 ) );
senstra ( :, senstype == 1 ) = -1;

% Creates the FieldTrip-style sensor definition.
sensor          = [];
sensor.label    = channame;
sensor.chanpos  = chanpos;
sensor.chantype = repmat ( { 'eeg' }, size ( channame ) );
sensor.chanunit = repmat ( { 'uV'  }, size ( channame ) );
sensor.elecpos  = senspos;
sensor.calib    = chancal;
sensor.tra      = senstra;
sensor.unit     = 'cm';
