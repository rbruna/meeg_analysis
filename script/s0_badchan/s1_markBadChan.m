clc
clear
close all

% Sets the paths.
config.path.meta = '../../meta/bad/';
config.path.patt = '*.mat';

% Sets the visualization configuration parameters.
config.trialfun       = 'restingSegmentation';
config.segment        = 60;
config.overlap        = 30;
config.equal          = false;
config.padding        = 2;
config.addpadd        = false;

config.channel.data   = { 'MEG' };
config.channel.ignore = {};

% Determines if the EEG data should be re-referenced.
config.channel.EEGref = 'average';
config.channel.hide   = 'zeros';

% Sets the filter band.
config.filter.band    = [ 2 45 ]; % [ 2 95 ];

% Action when the task have already been processed.
config.overwrite      = true;

% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Lists the files.
files = dir ( sprintf ( '%s%s', config.path.meta, config.path.patt ) );
    
% Goes through each file.
for findex = 1: numel ( files )
    
    fprintf ( 1, 'Working with file %s.\n', files ( findex ).name );
    
    % Loads the current file.
    meta     = load ( sprintf ( '%s%s', config.path.meta, files ( findex ).name ) );
    if numel(meta.bad) &&  ~config.overwrite
        warning ( 'Ignoring %s (bad channels already present).', files ( findex ).name )
        continue
    end
    % Extracts the meta data.
    dataset  = meta.file;
    header   = meta.header;
    event    = meta.event;
    artifact = [];
    
    header.grad = ft_convert_units ( header.grad, 'm' );
    header.grad.chanunit ( strcmp ( header.grad.chantype, 'megplanar' ) ) = { 'T/m' };
    
    fprintf ( 1, '  Reading data from disk.\n' );
    
    % Gets the data.
    cfg         = [];
    cfg.dataset = dataset;
    cfg.header  = header;
    
    wholedata   = my_read_data ( cfg );
    
    
    % Selects the channels.
    cfg                  = [];
    cfg.channel          = { 'MEG' 'EOG' 'ECG' };
    cfg.precision        = 'single';
    cfg.feedback         = 'no';
    
    wholedata            = ft_preprocessing ( cfg, wholedata );
    wholedata.unit       = 'm';
    
    
    fprintf ( 1, '  Filtering the data in the band %0.0f - %0.0f Hz.\n', config.filter.band );
    
    % Calculates the optimal filter order from the desired padding.
    filtorder            = floor ( header.Fs * config.padding );
    downrate             = floor ( header.Fs / ( 2 * config.filter.band ( end ) ) );
    
    % Filters and downsamples the data.
    fir                  = fir1 ( filtorder, config.filter.band / ( wholedata.fsample / 2 ) );
    wholedata            = myft_filtfilt ( fir, 1, wholedata );
    wholedata            = my_downsample ( wholedata, downrate );
    
    % Downsamples the events.
    for eindex = 1: numel ( event )
        event ( eindex ).sample = round ( event ( eindex ).sample / downrate );
    end
    event (:)            = [];
    
    
    % Extracts the overlapping epochs for the artifact revision.
    trialfun             = str2func ( config.trialfun );
    
    fileconfig           = config;
    fileconfig.dataset   = meta.file;
    fileconfig.header    = wholedata.hdr;
    fileconfig.begtime   = NaN;
    fileconfig.endtime   = NaN;
    fileconfig.feedback  = 'no';
    
    fileconfig.trl       = trialfun ( fileconfig );
    
    trialdata            = ft_redefinetrial ( fileconfig, wholedata );
    clear wholedata;
    
    
    fprintf ( 1, '  Displaying the data.\n' );
    
    % Gets the list of non-MEG channels (EOG, EKG, etc.).
    MEG                 = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEG' },             trialdata.label ) ) );
    MEGMAG              = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEGMAG' },          trialdata.label ) ) );
    MEGGRAD             = find ( ismember ( trialdata.label', ft_channelselection ( { 'MEGGRAD' },         trialdata.label ) ) );
    EEG                 = find ( ismember ( trialdata.label', ft_channelselection ( { 'EEG' },             trialdata.label ) ) );
    physio              = find ( ismember ( trialdata.label', ft_channelselection ( { 'EOG' 'ECG' 'EMG' }, trialdata.label ) ) );
    
    % Sets the colors according to the channel type.
    chancol             = ones ( numel ( trialdata.label ), 1 );
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
    cfg.badchan         = meta.bad;
    cfg.selectmode      = 'markbadchannel';
    cfg.projinfo        = header.orig.projs;
    cfg.applyprojector  = true;
    
    cfg                 = my_databrowser ( cfg, trialdata );
    
    % Gets the updated list of bad channels.
    meta.bad            = cfg.badchan;
    
    % Saves the meta data.
    save ( '-v6', sprintf ( '%s%s', config.path.meta, files ( findex ).name ), '-struct', 'meta' );
end
