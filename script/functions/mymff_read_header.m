function header = mymff_read_header ( filename )

% Based on FieldTrip functions:
% * ft_read_header by Robert Oostenveld
% * read_mff_bin


% Gets the information from the signal header.
info     = mymff_read_info ( filename );


% Reads the XML files.
xmlfiles = dir ( sprintf ( '%s/*.xml', filename ) );
if isempty ( xmlfiles ), error ( 'No information found.' ), end

% Goes through each file.
for xindex = 1: numel ( xmlfiles )
    
    % Gets the XML information and the data tag.
    xmlinfo  = myxml_read ( sprintf ( '%s/%s', filename, xmlfiles ( xindex ).name ) );
    tagname  = fieldnames ( xmlinfo );
    tagname  = tagname ( ~strncmpi ( 'xml', tagname, 3 ) );
    tagname  = tagname ( ~strcmpi ( 'doctype', tagname ) );
    tagname  = tagname {1};
    
    % Adds the new XML informaton to the XML structure.
    if isfield ( info.xml, tagname )
        info.xml.( tagname ) = my_structcat ( info.xml.( tagname ), xmlinfo.( tagname ) );
    else
        info.xml.( tagname ) = xmlinfo.( tagname );
    end
end


% Gets the sensor layout information.
if isfield ( info.xml, 'sensorLayout' )
    
    % Keeps only the channels of types 0 and 1.
    sensinfo = [ info.xml.sensorLayout.sensors.sensor ];
    sensinfo = sensinfo ( ismember ( [ sensinfo.type ], { '0', '1' } ) );
    
    % Checks that the number of channels agrees.
    if numel ( sensinfo ) ~= info.nchannel (1)
        error ( 'Data label does not match.' )
    end
    
    % Gets the labels.
    sensname = [ sensinfo.name ];
    senstype = [ sensinfo.type ];
    sensnum  = [ sensinfo.number ];
    empty    = strcmp ( sensname, '' );
    sensdata = strcmp ( senstype, '0' );
    
    % Replaces the empty names for the channel number number.
    label    = sensname (:);
    label ( empty &  sensdata ) = strcat ( 'EEG', sensnum ( empty &  sensdata ) );
    label ( empty & ~sensdata ) = strcat ( 'REF', sensnum ( empty & ~sensdata ) );
    
    % Rewrites the names in Neuromag format.
    label ( empty &  sensdata ) = regexprep ( label ( empty &  sensdata ), '^EEG(\d)$'   , 'EEG00$1' );
    label ( empty &  sensdata ) = regexprep ( label ( empty &  sensdata ), '^EEG(\d{2})$', 'EEG0$1'  );
    
    
    % Tries to get the PIB box labels.
    if numel ( info.rawinfo ) == 2 &&  isfield ( info.xml, 'PNSSet' )
        
        pnssinfo = [ info.xml.PNSSet.sensors.sensor ];
        pnssname = [ pnssinfo.name ];
        
        % Checks that the number of channels agrees.
        if numel ( pnssinfo ) ~= info.nchannel (2)
            error ( 'Data label does not match.' )
        end
        
        label    = cat ( 1, label, pnssname (:) );
        
    else
        for sindex = 2: numel ( info.rawinfo )
            newlabel = strtrim ( cellstr ( num2str ( ( 1: info.nchannel ( sindex ) )' ) ) );
            newlabel = strcat ( 's', num2str ( sindex ), '_E', newlabel );
            label    = cat ( 1, label, newlabel (:) );
        end
    end
else
    for sindex = 1: numel ( info.rawinfo )
        newlabel = strtrim ( cellstr ( num2str ( ( 1: info.nchannel ( sindex ) )' ) ) );
        newlabel = strcat ( 's', num2str ( sindex ), '_E', newlabel );
        label    = cat ( 1, label, newlabel (:) );
    end
end

% Gets the calibration information.
if isfield ( info.xml.dataInfo (1).calibrations, 'calibration' )
    
    % Gets the signal calibration information.
    calinfo  = info.xml.dataInfo (1).calibrations.calibration;
    
    % Checks for the number of calibration factors.
    if numel ( calinfo.channels.ch ) ~= numel ( sensinfo )
        error ( 'Calibration coefficents does not match number of EEG channels.' )
    end
    
    % Gets the channel calibration.
    senscal  = str2double ( calinfo.channels.ch (:) );
else
    
    % Sets the calibration to 1.
    senscal  = ones ( info.nchannel (1), 1 );
end

% Looks for calibration for the extra channels.
for dindex = 2: numel ( info.xml.dataInfo )
    if ~isempty ( info.xml.dataInfo ( dindex ).calibrations )
    else
        senscal  = cat ( 1, senscal, ones ( info.nchannel ( dindex ), 1 ) );
    end
end

% Adds the transformation form uV to V.
info.chan.label = label;
info.chan.calib = 1e-6 * senscal;


% Checks if multiple epochs are present.
if isfield ( info.xml, 'epochs' )
    
    % Gets the epoch definition in micro- or picoseconds.
    epochs          = cell ( numel ( info.xml.epochs, 3 ) );
    epochs ( :, 1 ) = cat ( 1, info.xml.epochs.epoch.beginTime );
    epochs ( :, 2 ) = cat ( 1, info.xml.epochs.epoch.endTime );
    epochs ( :, 3 ) = cat ( 1, info.xml.epochs.epoch.beginTime );
    epochs          = str2double ( epochs );
    
%     % add info to header about which sample correspond to which epochs, becasue this is quite hard for user to get...
%     epochdef = zeros(length(xmlinfo.epochs),3);
%     for iEpoch = 1:length(xmlinfo.epochs)
%         if iEpoch == 1
%             epochdef(iEpoch,1) = round(str2double(xmlinfo.epochs(iEpoch).epoch.beginTime)./(1000000./fsample))+1;
%             epochdef(iEpoch,2) = round(str2double(xmlinfo.epochs(iEpoch).epoch.endTime  )./(1000000./fsample));
%             epochdef(iEpoch,3) = round(str2double(xmlinfo.epochs(iEpoch).epoch.beginTime)./(1000000./fsample)); % offset corresponds to timing
%         else
%             NbSampEpoch = round(str2double(xmlinfo.epochs(iEpoch).epoch.endTime)./(1000000./fsample) - str2double(xmlinfo.epochs(iEpoch).epoch.beginTime)./(1000000./fsample));
%             epochdef(iEpoch,1) = epochdef(iEpoch-1,2) + 1;
%             epochdef(iEpoch,2) = epochdef(iEpoch-1,2) + NbSampEpoch;
%             epochdef(iEpoch,3) = round(str2double(xmlinfo.epochs(iEpoch).epoch.beginTime)./(1000000./fsample)); % offset corresponds to timing
%         end
%     end
    
    % Tries to find out the time scale.
    if round ( epochs ( end, 2 ) * info.fsample / sum ( info.nsample ) ) == 1e6
        epochs = round ( epochs * 1e-6 * info.fsample );
    elseif round ( epochs ( end, 2 ) * info.fsample / sum ( info.nsample ) ) == 1e9
        epochs = round ( epochs * 1e-9 * info.fsample );
    else
        error ( 'The number of samples do not match.' )
    end
    
    % Corrects the begining sample.
    epochs ( :, 1 ) = epochs ( :, 1 ) + 1;
    
    % Checks the consistency of the epochs.
    if size ( epochs, 1 ) > 1
        if numel ( unique ( diff ( epochs ( :, 1: 2 ), [], 2 ) ) ) == 1
            nsample = diff ( epochs ( 1, 1: 2 ) );
            ntrial  = size ( epochs, 1 );
        else
            error ( 'Epochs of different length.' );
        end
    else
        nsample = sum ( info.nsample );
        ntrial  = 1;
    end
else
    nsample = sum ( info.nsample );
    ntrial  = 1;
end

info.epochs        = epochs;

header             = [];
header.orig        = info;
header.label       = label;
header.Fs          = info.fsample;
header.nChans      = sum ( info.nchannel );
header.nSamplesPre = 0;
header.nSamples    = nsample;
header.nTrials     = ntrial;
