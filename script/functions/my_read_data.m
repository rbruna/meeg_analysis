function data = my_read_data ( cfg )

if isfield ( cfg, 'dataset' )
    dataset         = cfg.dataset;
else
    error ( 'No dataset provided.' );
end

if isfield ( cfg, 'header' )
    header          = cfg.header;
else
    header          = my_read_header ( dataset );
end

if isfield ( cfg, 'channel' )
    channel         = ft_channelselection ( cfg.channel, header.label );
    channel         = ismember ( header.label, channel );
    channel         = find ( channel );
else
    channel         = 1: numel ( header.label );
end

if isfield ( cfg, 'padding' )
    padsamples      = round ( cfg.padding * header.Fs );
else
    padsamples      = 0;
end 

if isfield ( cfg, 'begtime' ) && ~isnan ( cfg.begtime )
    begsample       = round ( cfg.begtime * header.Fs ) - padsamples;
else
    begsample       = 1;
end

if isfield ( cfg, 'endtime' ) && ~isnan ( cfg.endtime )
    endsample       = round ( cfg.endtime * header.Fs ) + padsamples;
else
    endsample       = header.nSamples;
end

% Only FIFF allows padding from outside the data.
if begsample < 1
    warning ( 'The padding extends outside the limits of the data.' );
    begsample = 1;
end

% Only FIFF allows padding from outside the data.
if endsample > header.nSamples
    warning ( 'The padding extends outside the limits of the data.' );
    endsample = header.nSamples;
end


% Gets the data.
if ft_filetype ( dataset, 'neuromag_fif' )
    
    % FIFF data count doesn't start in 0. Corrects it.
    fiffbegsample   = int32 ( begsample ) + header.orig.raw (1).first_samp - 1;
    fiffendsample   = int32 ( endsample ) + header.orig.raw (1).first_samp - 1;
    
    rawdata         = myfiff_read_raw ( dataset, fiffbegsample, fiffendsample, channel );
%     rawinfo         = fiff_setup_read_raw ( cfg.dataset );
%     rawdata         = fiff_read_raw_segment ( rawinfo, begsample, endsample, channel );
    
elseif ft_filetype ( dataset, 'egi_mff' )
    rawdata         = mymff_read_data ( dataset, header, begsample, endsample, channel );
    
elseif ft_filetype ( dataset, 'ns_cnt' )
    rawdata         = mycnt_read_data ( dataset, 'sbeg', begsample, 'seng', endsample, 'channel', channel );
    
elseif ft_filetype ( dataset, 'brainvision_vhdr' ) || ft_filetype ( dataset, 'brainvision_eeg' )
    rawdata         = mybv_read_data ( dataset, header, begsample, endsample, channel );
    
else
    
    % Rellies on FieldTrip to get the data.
    rawdata         = ft_read_data ( dataset, 'begsample', begsample, 'endsample', endsample, 'chanindx', channel );
end

% Fills the metadata.
data            = [];
data.hdr        = header;
data.label      = header.label ( channel );
data.time       = [];
data.trial      = [];
data.fsample    = header.Fs;
data.sampleinfo = [ begsample endsample ];

% Fills the data.
data.trial      = { rawdata };
data.time       = { ( single ( begsample: endsample ) - 1 ) / header.Fs };

% Gets the metadata, if available.
if isfield ( header, 'chantype' )
    data.chantype   = header.chantype ( channel );
end
if isfield ( header, 'chanunit' )
    data.chanunit   = header.chanunit ( channel );
end

% Includes the sensor information, if available.
if isfield ( header, 'grad' )
    data.grad       = header.grad;
end
if isfield ( header, 'elec' )
    data.elec       = header.elec;
end
