function header = myeep_read_header ( filename, rifftree )


% Reads the RIFF file tree, if required.
if nargin < 2
    rifftree = myriff_read ( filename );
end


% Gets the EEP header.
rawinfo  = myeep_read_info ( filename, rifftree );

% Builds the FieldTrip header from the system-specific header.
header             = [];
header.orig        = rawinfo;
header.Fs          = rawinfo.sample_rate;
header.label       = { rawinfo.channels.label }';
header.nChans      = rawinfo.channel_count;
header.nSamples    = rawinfo.sample_count;
header.nSamplesPre = 0;
header.nTrials     = 1;
header.chantype    = repmat ( { 'EEG' }, rawinfo.channel_count, 1 );
header.chanunit    = { rawinfo.channels.unit }';


% Tries to fill the (extended) 10-20 positions.
if ft_senstype ( header.label, 'eeg1005' )
    
    % Loads the standard EEG positions.
    elec               = ft_read_sens ( 'standard_1005.elc' );
    
    % Keeps only the desired channels.
    header.elec        = my_fixsens ( elec, header.label );
end
