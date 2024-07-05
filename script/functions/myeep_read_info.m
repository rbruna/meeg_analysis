function rawinfo = myeep_read_info ( filename, rifftree )


% Reads the RIFF file tree, if required.
if nargin < 2
    rifftree = myriff_read ( filename );
end


% Gets the EEP header.
subtree  = myriff_subtree ( rifftree, 'eeph' );
dummy    = char ( subtree.data (:)' );

% Looks for the file version.
hits     = regexp ( dummy, '\[File Version\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.file_version = strtrim ( hits {1} {1} );
end

% Looks for the sampling rate.
hits     = regexp ( dummy, '\[Sampling Rate\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.sample_rate = str2double ( hits {1} {1} );
end

% Looks for the number of samples.
hits     = regexp ( dummy, '\[Samples\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.sample_count = str2double ( hits {1} {1} );
end

% Looks for the number of channels.
hits     = regexp ( dummy, '\[Channels\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.channel_count = str2double ( hits {1} {1} );
end

% Looks for the channel information.
hits     = regexp ( dummy, '\[Basic Channel Data\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    chaninfo = strtrim ( hits {1} {1} );
    
    % Checks for the (mandatory) channel information header.
    hits     = regexp ( chaninfo, ';label(?:[\s]+)calibration factor(.*)', 'tokens' );
    if isempty ( hits )
        error ( 'The channel information is not correct. Cannot continue.' );
    end
    
    chaninfo = hits {1} {1};
    chaninfo = cat ( 2, chaninfo, newline );
    
    
    % Parses the channel definition.
    chaninfo = textscan ( chaninfo, '%s %f %f %s %s' );
    
    % Gets the data.
    chanlab  = strtrim ( chaninfo {1} );
    chancal  = chaninfo {2} .* chaninfo {3};
    chanunit = strtrim ( chaninfo {4} );
    chanref  = strtrim ( chaninfo {5} );
    
    % Changes the calibration so the output is in SI units (volts).
    chanuV   = strcmp ( chanunit, 'uV' );
    chancal  ( chanuV ) = 1e-6 * chancal ( chanuV );
    chanunit ( chanuV ) = { 'V' };
    
    % Stores the channel information.
    chaninfo = struct ( 'label', chanlab, 'calibration', num2cell ( chancal ), 'unit', chanunit, 'reference', chanref );
    
    % Checks that the number of channels matches.
    if numel ( chaninfo ) ~= rawinfo.channel_count
        error ( 'The channel definition does not match the channels.' );
    end
    
    % Stores the channel information.
    rawinfo.channels = chaninfo;
else
    error ( 'No channel definition. Cannot continue.' );
end


% Gets the acquisition information.
subtree  = myriff_subtree ( rifftree, 'info' );
dummy    = char ( subtree.data (:)' );

% Looks for the acquisition date and fraction.
hits     = regexp ( dummy, '\[StartDate\]([^\[]*)[.]*\[StartFraction\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    acqdate  = str2double ( strtrim ( hits {1} {1} ) );
    acqfrac  = str2double ( strtrim ( hits {1} {2} ) );
    
    % Converts the acquisition date into POSIX time format.
    rawinfo.acquisition_time = acqdate * ( 60 * 60 * 24 ) - 2209161600 + acqfrac;
end

% Looks for the software identification.
hits     = regexp ( dummy, '\[MachineMake\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.software_id = strtrim (  hits {1} {1} );
end

% Looks for the amplifier identification.
hits     = regexp ( dummy, '\[MachineModel\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.hardware_id = strtrim ( hits {1} {1} );
end

% Looks for the subject name.
hits     = regexp ( dummy, '\[SubjectName\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.subject_name = strtrim ( hits {1} {1} );
end

% Looks for the subject birth date.
hits     = regexp ( dummy, '\[SubjectDateOfBirth\]([^\[]*)', 'tokens' );
if ~isempty ( hits )
    rawinfo.subject_birth = str2num ( hits {1} {1} ); %#ok<ST2NM>
end



% Gets the event definition.
rawevent = myriff_subtree ( rifftree, 'evt' );
rawinfo.rawevent = rawevent;


% % Other fields not used.
% subtree  = myriff_subtree ( rifftree, 'tfh' );



% Tries to read the sidecar segment file.
segfile  = regexprep ( filename, '.cnt$', '.seg' );
rawseg   = myeep_read_seg ( segfile );

% Adds the information of the first segment.
rawseg1  = struct ( ...
    'identifier',   1, ...
    'start_time',   rawinfo.acquisition_time, ...
    'sample_count', rawinfo.sample_count - sum ( cat ( 1, rawseg.sample_count ) ) );
rawseg   = cat ( 1, rawseg1, rawseg (:) );

% Gets the first sample for each segment.
samples  = cat ( 1, rawseg.sample_count );
sample1  = rawinfo.sample_count - flipud ( cumsum ( flipud ( samples ) ) ) + 1;
sample1  = num2cell ( sample1 );

% Adds the information about the first sample.
[ rawseg.start_sample ] = sample1 {:};

% Stores the segment information.
rawinfo.segments = rawseg;



% Tries to read the sidecar event file.
evtfile  = regexprep ( filename, '.cnt$', '.evt' );
rawinfo.events = myeep_read_evt ( evtfile );
