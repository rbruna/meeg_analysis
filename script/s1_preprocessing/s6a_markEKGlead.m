clc
clear
close all

% Sets the paths.
config.path.sketch      = '../../data/sketch/';
config.path.patt        = '*.mat';

config.channel.ignore   = {};

% Determines if the EEG data should be re-referenced.
config.channel.EEGref   = 'average';
config.channel.hide     = 'zeros';

% Sets the component removal configuration parameters.
config.deEKG.comptype   = 2;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Gets the list of subjects.
files = dir ( sprintf ( '%s%s', config.path.sketch, config.path.patt ) );

% Goes through each file.
for findex = 1: numel ( files )
    
    % Gets the file names.
    basename            = files ( findex ).name;
    datafile            = sprintf ( '%s%s', config.path.sketch, basename );
    
    % Loads the data.
    sketchdata          = load ( datafile, '-regexp', '^(?!erfdata|freqdata$).' );
    
    
    % Gets the message name of the subject-task-stage set.
    msgtext   = sprintf ( 'subject ''%s'', task ''%s''', sketchdata.subject, sketchdata.task );
    if ~isempty ( sketchdata.stage )
        msgtext   = sprintf ( '%s, stage ''%s''', msgtext, sketchdata.stage );
    end
    msgtext   = sprintf ( '%s, channel group ''%s''', msgtext, sketchdata.channel );
    
    % Looks for EKG components.
    if ~any ( sketchdata.cleaninfo.comp.type == config.deEKG.comptype )
        fprintf ( 1, 'Ignoring %s (no EKG components).\n', msgtext );
        continue
    end
    
    fprintf ( 1, 'Cleaning data for %s.\n', msgtext );
    
    % Gets the data and component information.
    fileinfo            = sketchdata.fileinfo;
    trialinfo           = sketchdata.trialinfo;
    compinfo            = sketchdata.compinfo.SOBI;
    cleaninfo           = sketchdata.cleaninfo;
    
    % Removes the artifacted or noisy trials.
    trialclean          = cleaninfo.trial.type == 0;
    trialinfo.trialdef  = trialinfo.trialdef  ( trialclean, : );
    trialinfo.trialfile = trialinfo.trialfile ( trialclean, : );
    trialinfo.trialpad  = trialinfo.trialpad  ( trialclean, : );
    
    
    % Gets the files with data on them.
    ifiles              = unique ( trialinfo.trialfile );
    
    % Gets the offsets from the file header.
    headers             = cat ( 1, fileinfo.header );
    offsets             = cumsum ( cat ( 1, 0, headers.nSamples ) );
    
    % Modifies the trial definitions.
    trialdef            = trialinfo.trialdef;
    trialdef ( :, 1 )   = trialdef ( :, 1 ) + offsets ( trialinfo.trialfile );
    trialdef ( :, 2 )   = trialdef ( :, 2 ) + offsets ( trialinfo.trialfile );
    
    
    % Loads the whole files.
    wholedatas          = cell ( size ( ifiles ) );
    for iindex = 1: numel ( ifiles )
        
        fprintf ( 1, '  Loading data from file %i.\n', iindex );
        
        % Loads the data.
        cfg                 = [];
        cfg.dataset         = fileinfo ( iindex ).dataset;
        cfg.header          = fileinfo ( iindex ).header;
        cfg.begtime         = fileinfo ( iindex ).begtime;
        cfg.endtime         = fileinfo ( iindex ).endtime;
        cfg.channel         = cat ( 2, { sketchdata.channel }, { 'ECG' } );
        
        wholedata           = my_read_data ( cfg );
        
        % Corrects the sample information.
        wholedata.sampleinfo ( :, 1 ) = wholedata.sampleinfo ( :, 1 ) + offsets ( ifiles ( iindex ) );
        wholedata.sampleinfo ( :, 2 ) = wholedata.sampleinfo ( :, 2 ) + offsets ( ifiles ( iindex ) );
        
        % Stores the data.
        wholedatas { iindex } = wholedata;
    end
    
    fprintf ( 1, '  Concatenating the data from all the files.\n' );
    
    % Joins the data.
    cfg                 = [];
    
    wholedata           = myft_appenddata ( cfg, wholedatas {:} );
    clear wholedatas
    
    % Re-references the EEG data, if requested.
    chconfig  = config.channel;
    chconfig.bad = sketchdata.chaninfo.bad;
    
    wholedata = my_EEGreref ( wholedata, chconfig );
    
    
    fprintf ( 1, '  Segmenting the data using the trial definition.\n' );
    
    % Adds one second of padding for the filter.
    trialpad              = round ( wholedata.fsample );
    trialdefpad           = trialdef;
    trialdefpad ( :, 1 )  = trialdef ( :, 1 ) - trialpad;
    trialdefpad ( :, 2 )  = trialdef ( :, 2 ) + trialpad;
    trialdefpad ( :, 3 )  = trialdef ( :, 3 ) - trialpad;
    
    % Re-segments the data according to the trial definition.
    cfg                 = [];
    cfg.trl             = trialdefpad;
    cfg.feedback        = 'no';
    
    trialdata           = ft_redefinetrial ( cfg, wholedata );
    clear wholedata
    
    % Removes the 'cfg' field.
    trialdata           = rmfield ( trialdata, 'cfg' );
    
    % Rewrites the data as 'single' to save space.
    trialdata.trial     = cellfun ( @single, trialdata.trial, 'UniformOutput', false );
    
    
    fprintf ( 1, '  Calculating the component data.\n' );
    
    % Gets the component types.
    comptype            = cleaninfo.comp.type;
    
    % Gets the position of the channels needed for the components.
    compchans           = my_matchstr ( trialdata.label, compinfo.topolabel );
    
    % Gets the raw data in matrix form.
    rawdata             = cat ( 3, trialdata.trial {:} );
    
    % Gets the EKG components.
    EKGcomp      = comptype == config.deEKG.comptype;
    EKGunmixing  = compinfo.unmixing ( EKGcomp, : );
    EKGcompshape = size ( rawdata );
    EKGcompshape (1) = size ( EKGunmixing, 1 );
    EKGcompdata  = EKGunmixing * rawdata ( compchans, : );
    EKGcompdata  = reshape ( EKGcompdata, EKGcompshape );
    
    % Labels the EKG lead candidates.
    EKGcomplabel = cell ( size ( EKGcompdata, 1 ), 1 );
    
    for cindex = 1: size ( EKGcompdata, 1 )
        EKGcomplabel { cindex } = sprintf ( 'IC %d', cindex );
    end
    
    % Gets the EKG channel, if any.
    cfg          = [];
    cfg.channel  = 'ECG';
    
    EKGchandata  = ft_selectdata ( cfg, trialdata );
    EKGchanlabel = EKGchandata.label;
    EKGchandata  = cat ( 3, EKGchandata.trial {:} );
    
    % List all the EKG lead candidates.
    EKGleadcand  = cat ( 1, EKGchandata, EKGcompdata );
    EKGcandlabel = cat ( 1, EKGchanlabel, EKGcomplabel );
    
    % Asks for the leading component.
    lead = selectEKGlead ( EKGleadcand, EKGcandlabel );
    drawnow
    
    if lead
        if lead <= numel ( EKGchanlabel )
            EKGlead          = [];
            EKGlead.label    = EKGchanlabel ( lead );
            EKGlead.unmixing = 1;
        else
            EKGlead          = [];
            EKGlead.label    = compinfo.topolabel;
            EKGlead.unmixing = EKGunmixing ( lead - numel ( EKGchanlabel ), : );
        end
    else
        EKGlead = [];
    end
    
    
    % Stores the EKG leading component.
    cleaninfo.EKGlead = EKGlead;
    
    % Saves the data.
    save ( '-v6', datafile, '-append', 'cleaninfo' );
end
