clc
clear
close all

config.path.segs = '../../data/segments/';
config.path.patt = '*.mat';

% Sets the filter band.
config.filter.band    = [ 2 45 ];


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Gets the list of files.
files = dir ( sprintf ( '%s%s', config.path.segs, config.path.patt ) );

% Goes through each file.
for findex = 1: numel ( files )
    
    % Gets the current file name.
    filename    = files ( findex ).name;
    
    % Preloads the data.
    epochdata   = load ( sprintf ( '%s%s', config.path.segs, filename ), 'subject', 'task', 'channel' );
    
    fprintf ( 1, 'Checking data for subject ''%s'', task ''%s'', channel group ''%s''.\n', epochdata.subject, epochdata.task, epochdata.channel );
    
    
    fprintf ( 1, '  Loading the data.\n' );
    
    % Loads the data.
    epochdata   = load ( sprintf ( '%s%s', config.path.segs, filename ) );
    
    % Gets the real data.
    trialdata = epochdata.trialdata;
    trialinfo = epochdata.trialinfo;
    
    trialdata.hdr = epochdata.fileinfo (1).header;
    
    
    fprintf ( 1, '  Filtering the data in the band %0.0f - %0.0f Hz.\n', config.filter.band );
    
    % Claculates the optimal order of the filter.
    filtorder = round ( trialinfo.trialpad (1) * trialdata.fsample );
    filtorder = min ( filtorder, floor ( numel ( trialdata.time {1} ) / 3 ) );
    
    % Calculates the optimal downsampling rate for the frequency band.
    downrate  = floor ( trialdata.fsample / ( 2 * config.filter.band ( end ) ) );
    
    % Filters and downsamples the data.
    fir       = fir1 ( filtorder, config.filter.band / ( trialdata.fsample / 2 ) );
    trialdata = myft_filtfilt ( fir, 1, trialdata );
    trialdata = my_downsample ( trialdata, downrate );
    
        
    % Gets the lenght of the padding in samples.
    trialpad  = round ( trialinfo.trialpad (1) * trialdata.fsample );
    triallen  = numel ( trialdata.time {1} );
    ntrial    = numel ( trialdata.time );
        
    % Generates a fake sample information for the trials.
    sampinfo  = ( 0: 1: ntrial - 1 )' * triallen + 1;
    sampinfo  = cat ( 2, sampinfo, sampinfo + triallen - 1 );
    
    % Adds the fake sample information to the data.
    trialdata.sampleinfo = sampinfo;
    
    
    % Generates an artifact definition for the padding.
    artinfo   = ( 0: 1: ntrial - 1 )' * triallen + 1;
    artinfo   = cat ( 2, artinfo, artinfo + trialpad - 1 );
    artinfo   = cat ( 1, artinfo, artinfo + triallen - trialpad );
    artinfo   = sortrows ( artinfo );
    
    artifact  = [];
    artifact.visual.artifact = artinfo;
    
    % Generates an empty event structure.
    event = [];
    
    
    
    % Gets the list of non-MEG channels (EOG, EKG, etc.).
    MEG                 = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEG' },             trialdata.label ) ) );
    MEGMAG              = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEGMAG' },          trialdata.label ) ) );
    MEGGRAD             = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEGGRAD' },         trialdata.label ) ) );
    EEG                 = find ( ismember ( trialdata.label', ft_channelselection ( { 'EEG' },             trialdata.label ) ) );
    physio              = find ( ismember ( trialdata.label', ft_channelselection ( { 'EOG' 'ECG' 'EMG' }, trialdata.label ) ) );
    
    % Sets the colors according to the channel type.
    chancol             = zeros ( numel ( trialdata.label ), 1 );
    chancol ( MEG )     = 1;
    chancol ( MEGMAG )  = 2;
    chancol ( MEGGRAD ) = 3;
    chancol ( EEG )     = 4;
    chancol ( physio )  = 5;
    
    % Displays the MEG data to append or remove artifacts.
    cfg = [];
    cfg.channel         = 1: 30;
    cfg.physio          = physio;
    cfg.gradscale       = 0.05;
    cfg.eegscale        = 5e-8;
    cfg.eogscale        = 1e-8;
    cfg.ecgscale        = 1e-8;
    cfg.ylim            = [ -2 2 ] * 1e-12;
    cfg.plotlabels      = 'yes';
    cfg.viewmode        = 'vertical';
    cfg.continous       = 'yes';
    cfg.colorgroups     = chancol;
    cfg.channelcolormap = [   0 114 189;   0 114 189; 162  20  47; 217  83  25; 126  47 142 ] / 255;
    cfg.artfctdef       = artifact;
    cfg.ploteventlabels = 'colorvalue';
    cfg.event           = event;
    
    cfg                 = my_databrowser ( cfg, trialdata );
    drawnow
end
