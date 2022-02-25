function sensor = mymff_sensors ( info )


% If the data already have a sensor definition does nothing.
if isfield ( info, 'sensor' ) && isstruct ( info.sensor ) && ~isempty ( info.sensor )
    sensor       = info.sensor;
    return
end


% Gets the sensor information.
sensinfo     = info.xml.sensorLayout.sensors.sensor;

% Takes only the EEG (type 0) and reference (type 1) channels.
sensinfo     = sensinfo ( ismember ( str2double ( [ sensinfo.type ] ), [ 0 1 ] ) );


% Gets the channel type.
senstype     = [ sensinfo.type ];
senstype     = str2double ( senstype );

% Gets the channel number.
sensnumber   = [ sensinfo.number ];
sensnumber   = str2double ( sensnumber );

% Gets the channel names.
sensname     = [ sensinfo.name ];
emptyname    = cellfun ( @isempty, sensname );

% Creates a channel name, if none provided.
if any ( emptyname & senstype == 0 )
    sensname ( emptyname & senstype == 0 ) = strcat ( 'EEG', cat ( 1, sensinfo ( emptyname & senstype == 0 ).number ) );
end
if any ( emptyname & senstype == 1 )
    sensname ( emptyname & senstype == 1 ) = strcat ( 'REF', cat ( 1, sensinfo ( emptyname & senstype == 1 ).number ) );
end

% Checks for calibration information.
if isfield ( info.xml.dataInfo(1).calibrations, 'calibration' )
    
    % Gets the signal calibration information.
    calinfo      = info.xml.dataInfo(1).calibrations.calibration;
    
    % Checks for the number of calibration factors.
    if numel ( calinfo.channels.ch ) ~= numel ( sensinfo )
        error ( 'Calibration coefficents does not match number of EEG channels.' )
    end
    
    % Gets the channel calibration.
    senscal      = str2double ( calinfo.channels.ch );
else
    
    % Sets the calibration to 1.
    senscal      = ones ( size ( sensnumber ) );
end


% Sets the formatted channel information.
senstype     = num2cell   ( senstype );
sensnumber   = num2cell   ( sensnumber );
senscal      = num2cell   ( senscal );

sensor       = struct ( ...
    'type',   senstype, ...
    'name',   sensname, ...
    'number', sensnumber, ...
    'cal',    senscal );
