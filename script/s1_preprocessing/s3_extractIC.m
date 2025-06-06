clc
clear
close all

% Sets the paths.
config.path.trl       = '../../meta/trl/';
config.path.patt      = '*.mat';

% Action when the task have already been processed.
config.overwrite      = true;

% Sets the segmentation parameters.
config.trialfun       = 'restingSegmentation';
config.segment        = 4;
config.padding        = 2;
config.addpadd        = false;

% Artifacts to exclude of the IC analysis.
config.artifact       = { 'visual' 'jump' 'muscle' };

% Sets the IC analisys parameters.
config.channel.groups = { 'MEGMAG' 'MEGGRAD' 'EEG' };
config.channel.ignore = {};

% Sets the filter band.
config.filter.band    = [ 2 45 ];


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Gets the list of taks files.
files = dir ( sprintf ( '%s%s', config.path.trl, config.path.patt ) );

% Goes through each subject and task.
for sindex = 1: numel ( files )
    filename          = files ( sindex ).name;
    filename          = sprintf ( '%s%s', config.path.trl, filename );
    
    % Loads the current task information.
    taskinfo          = load ( filename );
    
    % Gets the message name of the subject-task-stage set.
    msgtext   = sprintf ( 'subject ''%s'', task ''%s''', taskinfo.subject, taskinfo.task );
    if ~isempty ( taskinfo.stage )
        msgtext   = sprintf ( '%s, stage ''%s''', msgtext, taskinfo.stage );
    end
    
    % Checks if the task has already been processed.
    if isfield ( taskinfo, 'compinfo' ) && ~config.overwrite
        
        fprintf ( 1, 'Ignoring %s (already calculated).\n', msgtext );
        continue
    end
    
    fprintf ( 1, 'Working on %s.\n', msgtext );
    
    % Reserves memory for the data segments.
    datas             = cell ( numel ( taskinfo.fileinfo ), 1 );
    headers           = cell ( numel ( taskinfo.fileinfo ), 1 );
    
    % Calculates the optimal downsampling rate for the frequency band.
    downrate          = floor ( taskinfo.fileinfo (1).header.Fs / ( 2 * config.filter.band ( end ) ) );
    
    % Calculates the optimal filter order from the desired padding.
    filtorder         = floor ( taskinfo.fileinfo (1).header.Fs * config.padding );
    
    
    % Goes through all the data files.
    for findex = 1: numel ( taskinfo.fileinfo )
        
        % Gets the current epochs and artifact definitions.
        fileinfo            = taskinfo.fileinfo  ( findex );
        artinfo             = taskinfo.artinfo ( findex );
        
        [ ~, name, ext ]    = fileparts ( taskinfo.fileinfo ( findex ).dataset );
        basename            = strcat ( name, ext );
        
        if ~exist ( fileinfo.dataset, 'file' )
            fprintf ( 1, '  Ignoring file %i (file %s not found).\n', findex, basename );
            continue
        end
        
        fprintf ( 1, '  Processing file %i (%s).\n', findex, basename );
        

        fprintf ( 1, '    Looking for artifact-free epochs in the file.\n' );
        
        % Gets the artifact free epochs.
        trialfun            = str2func ( config.trialfun );
        
        fileconfig          = config;
        fileconfig.dataset  = fileinfo.dataset;
        fileconfig.header   = fileinfo.header;
        fileconfig.begtime  = fileinfo.begtime;
        fileconfig.endtime  = fileinfo.endtime;
        fileconfig.feedback = 'no';
        
        fileconfig.artifact = artinfo.artifact;
        fileconfig.artifact = rmfield ( fileconfig.artifact, setdiff ( fieldnames ( artinfo.artifact ), config.artifact ) );
        
        trialdef            = trialfun ( fileconfig );
        
        % If no clean epochs, skips the file.
        if isempty ( trialdef )
            fprintf ( 1, '    No clean data. Skipping the file.\n' );
            continue
        end


        fprintf ( 1, '    Reading data from disk.\n' );
        
        % Gets the MEG data.
        cfg                 = [];
        cfg.dataset         = fileinfo.dataset;
        cfg.header          = fileinfo.header;
        
        wholedata           = my_read_data ( cfg );
        
        % Selects the channels.
        cfg                 = [];
        cfg.channel         = cat ( 2, config.channel.groups, strcat ( '-', config.channel.ignore ) );
        cfg.precision       = 'single';
        cfg.feedback        = 'no';
        
        wholedata           = ft_preprocessing ( cfg, wholedata );
        
        
        fprintf ( 1, '    Filtering the data in the band %0.0f - %0.0f Hz.\n', config.filter.band );
        
        % Filters the data.
        fir                 = fir1 ( filtorder, config.filter.band / ( wholedata.fsample / 2 ) );
        wholedata           = myft_filtfilt ( fir, 1, wholedata );
        
        
        fprintf ( 1, '    Segmenting the data.\n' );
        
        % Segments the data according to the trial definition.
        cfg                 = config;
        cfg.trl             = trialdef;
        cfg.feedback        = 'no';
        
        trialdata           = ft_redefinetrial ( cfg, wholedata );
        trialdata.trial     = cellfun ( @single, trialdata.trial, 'UniformOutput', false );

        % Downsamples the data.
        trialdata           = my_downsample ( trialdata, downrate );
        
        
        % Stores the epoch data.
        datas   { findex }  = cat ( 3, trialdata.trial {:} );
        headers { findex }  = trialdata.hdr;
        
        clear trialdata
    end
    
    % Converts the data cell to a matrix.
    datas             = cat ( 3, datas {:} );
    headers           = cat ( 1, headers {:} );
    
    if isempty ( datas )
        fprintf ( 1, '  Ignoring subject ''%s'' (no clean data found in any file).\n', taskinfo.subject );
        continue
    end
    
    % Limits the number of trials to a maximum of 200.
    if size ( datas, 3 ) > 200
        sample = sort ( randsample ( size ( datas, 3 ), 200 ) );
        datas  = datas ( :, :, sample );
    end
    
    
    % Recovers the SOBI information.
    if isfield ( taskinfo, 'compinfo' )
        compinfo          = taskinfo.compinfo;
        
        SOBI              = compinfo.SOBI;
        
    % If no SOBI information initializes the information structure.
    else
        compinfo          = [];
        compinfo.step     = [];
        compinfo.date     = [];
        compinfo.config   = [];
        compinfo.types    = [];
        compinfo.SOBI     = [];
        compinfo.history  = {};
        
        SOBI              = [];
    end
    
    % Goes through each channel group.
    for chindex = 1: numel ( config.channel.groups )
        
        channel  = config.channel.groups { chindex };
        
        % Gets the labels for this channel group.
        label    = ft_channelselection ( channel, headers (1).label );
        
        % Ignores the selected channels.
        label    = setdiff ( label, config.channel.ignore );
        label    = setdiff ( label, taskinfo.chaninfo.bad );
        
        if isempty ( label )
            fprintf ( 1, '  Ignoring channel group ''%s'' (no data).\n', channel );
            continue
        end
        
        fprintf ( 1, '  Working with channel group ''%s''.\n', channel );
        
        % Gets the channels and labels in the right order.
        chanindx = ismember ( headers (1).label, label );
        label    = headers (1).label ( chanindx );
        chandata = datas ( chanindx, :, : );
        
        fprintf ( 1, '    Extracting the SOBI components.\n' );
        fprintf ( 1, '      ' );
        
        % Gets the independen components for the current channel group.
        mixing   = my_sobi ( chandata );
        
        % Adds the channel group to the output.
        SOBI.( config.channel.groups { chindex } )           = [];
        SOBI.( config.channel.groups { chindex } ).topolabel = label;
        SOBI.( config.channel.groups { chindex } ).mixing    = mixing;
        SOBI.( config.channel.groups { chindex } ).unmixing  = pinv ( mixing );
        SOBI.( config.channel.groups { chindex } ).type      = zeros ( size ( label ) );
    end
    
    % Updates the current step structure.
    compinfo.step     = 'Component extraction';
    compinfo.date     = char ( datetime );
    compinfo.config   = config;
    compinfo.types    = { 'Clean component' };
    compinfo.SOBI     = SOBI;
    
    % Adds the current step to the file history.
    current           = rmfield ( compinfo, 'history' );
    compinfo.history  = [ compinfo.history current ];
    
    % Adds the SOBI information to the task information.
    taskinfo.compinfo = compinfo;
    
    % Saves the intependent components.
    save ( '-v6', filename, '-struct', 'taskinfo' )
end
