clc
clear
close all

% Sets the paths.
config.path.trl         = '../../meta/trl/';
config.path.sketch      = '../../data/sketch/';
config.path.patt        = '*.mat';

% Action when the task have already been processed.
config.overwrite        = false;


% Sets the path to the behavioural data and segmentation.
config.behavioural      = '../../meta/beh/';
config.behavioural      = false;

% If no behavioural data sets the segmentation configuration parameters.
config.trialfun         = 'trialfun';
config.prestim          = 0.2;
config.poststim         = 1.5;

% Defines the critical time window(s) in seconds.
config.crittoi ( 1, : ) = [ -0.2  1.5 ];

% Sets the extra trial segmentation options.
config.segment          = 4.0;
config.padding          = 1.0;

% Sets the sketch building options.
config.erfband          = [ 2 35 ];
config.freqband         = [ 2 45 ];

config.channel.groups   = { 'MEGMAG' 'MEGGRAD' 'EEG' };
config.channel.ignore   = {};


% Creates the output folder, if needed.
if ~exist ( config.path.sketch, 'dir' ), mkdir ( config.path.sketch ); end


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Gets the list of task files.
files = dir ( sprintf ( '%s%s', config.path.trl, config.path.patt ) );

% Goes through each subject and task.
for sindex = 1: numel ( files )
    
    filename            = files ( sindex ).name;
    filename            = sprintf ( '%s%s', config.path.trl,  filename );
    
    % Loads the independent component definition.
    taskinfo            = load ( filename );
    
    % Gets the message name of the subject-task-stage set.
    msgtext   = sprintf ( 'subject ''%s'', task ''%s''', taskinfo.subject, taskinfo.task );
    if ~isempty ( taskinfo.stage )
        msgtext   = sprintf ( '%s, stage ''%s''', msgtext, taskinfo.stage );
    end
    
    % Checks that the selected channel group is present in the SOBI data.
    if ~any ( ismember ( config.channel.groups, fieldnames ( taskinfo.compinfo.SOBI ) ) )
        fprintf ( 1, 'Ignoring %s (no SOBI information for the selected channel groups).\n', msgtext );
        continue
    end
    
    outnames = cell ( size ( config.channel ) );
    for findex = 1: numel ( config.channel.groups )
        channel = config.channel.groups { findex };
        outnames { findex } = sprintf ( '%s%s_%s_%s.mat', config.path.sketch, taskinfo.subject, taskinfo.task, channel );
    end
    if all ( cellfun ( @(f) exist ( f, 'file' ) ~= 0, outnames ) ) && ~config.overwrite
        fprintf ( 1, 'Ignoring %s (already calculated).\n', msgtext );
        continue
    end
    
    fprintf ( 1, 'Working on %s.\n', msgtext );
    
    % Gets the files length as a vector.
    headers             = [ taskinfo.fileinfo.header ];
    samples             = [ headers.nSamples ];
    offsets             = cat ( 2, 0, cumsum ( samples) );
    
    % Reserves memory for the trialdata.
    trialdefs           = cell ( numel ( taskinfo.fileinfo ), 1 );
    trialfiles          = cell ( numel ( taskinfo.fileinfo ), 1 );
    trialpads           = cell ( numel ( taskinfo.fileinfo ), 1 );
    trialtypes          = cell ( numel ( taskinfo.fileinfo ), 1 );
    erfdatas            = cell ( numel ( taskinfo.fileinfo ), 1 );
    freqdatas           = cell ( numel ( taskinfo.fileinfo ), 1 );
    
    % Goes through all the data files.
    for findex = 1: numel ( taskinfo.fileinfo )
        
        % Loads the current epochs and artifact definitions.
        fileinfo             = taskinfo.fileinfo ( findex );
        artinfo              = taskinfo.artinfo  ( findex );
        
        [ ~, name, ext ]     = fileparts ( taskinfo.fileinfo ( findex ).dataset );
        basename             = strcat ( name, ext );
        
        if ~exist ( fileinfo.dataset, 'file' )
            fprintf ( 1, '  Ignoring trial definition for file %i (%s file not found).\n', findex, basename );
            continue
        end
        
        fprintf ( 1, '  Processing file %i (%s).\n', findex, basename );
        
        fprintf ( 1, '    Reading data from disk.\n' );
        
        % Gets the MEG data.
        cfg                   = [];
        cfg.dataset           = fileinfo.dataset;
        cfg.header            = fileinfo.header;
        
        wholedata             = my_read_data ( cfg );
        
        % Selects the channels.
        cfg                   = [];
        cfg.channel           = cat ( 2, config.channel.groups, { 'EOG' 'ECG' 'EMG' }, strcat ( '-', config.channel.ignore ) );
        cfg.precision         = 'single';
        cfg.feedback          = 'no';
        
        wholedata             = ft_preprocessing ( cfg, wholedata );
       
        
        % If the behavioural data is defined loads it.
        if config.behavioural
            
            % Gets the behavioural file name.
            behfile               = sprintf ( '%s%s_%s.mat', config.behavioural, taskinfo.subject, taskinfo.task );
            
            if ~exist ( behfile, 'file' )
                fprintf ( 1, '    Behavioural file not found. Skipping.\n' );
                continue
            end
            
            fprintf ( 1, '    Loading the trial definition. ' );
            
            % Loads the behavioural data.
            behdata               = load ( behfile );
            
            % Extracts the trial definition.
            trialdef              = behdata.beh.trialdef;
            trialpad              = behdata.beh.trialpad;
            trialfile             = behdata.beh.trialfile;
            
            % Gets only the trials for the current file.
            trialdef              = trialdef ( trialfile == findex, : );
            trialpad              = trialpad ( trialfile == findex );
            
            % Gets the trial padding in samples.
            trialpad              = round ( trialpad * fileinfo.header.Fs );
            
            % Removes the explicit padding (Pablo).
            trialdef ( :, 1 )     = trialdef ( :, 1 ) + trialpad;
            trialdef ( :, 2 )     = trialdef ( :, 2 ) - trialpad;
            trialdef ( :, 3 )     = trialdef ( :, 3 ) + trialpad;
            
            % Corrects the samples offset.
            trialdef ( :, 1: 2 )  = trialdef ( :, 1: 2 ) - offsets ( findex );
            
            
            % Gets the pre-stim and post-stime times.
            triallen              = trialdef ( 1, 2 ) - trialdef ( 1, 1 );
            prestim               = - trialdef ( 1, 3 );
            poststim              = triallen - prestim;
            
            fprintf ( 1, '%i trials found.\n', size ( trialdef, 1 ) );
            
        % Otherwise uses the defined trial segmentation function.
        else
            
            fprintf ( 1, '    Generating the trial definition. ' );
            
            % Extracts the trials.
            trialfun              = str2func ( config.trialfun );
            
            fileconfig            = config;
            fileconfig.dataset    = fileinfo.dataset;
            fileconfig.header     = fileinfo.header;
            fileconfig.event      = fileinfo.event;
            fileconfig.begtime    = fileinfo.begtime;
            fileconfig.endtime    = fileinfo.endtime;
            fileconfig.feedback   = 'no';
            
            trialdef              = trialfun ( fileconfig );
            
            % If no trials ignores the file.
            if isempty ( trialdef )
                fprintf ( 1, 'No trials detected. Skipping file.\n' );
                continue
            end
            
            fprintf ( 1, '%i trials found.\n', size ( trialdef, 1 ) );
        end
        
        
        % Adds the padding for the filter.
        trialpad              = round ( config.padding * wholedata.fsample );
        trialdefpad           = trialdef;
        trialdefpad ( :, 1 )  = trialdef ( :, 1 ) - trialpad;
        trialdefpad ( :, 2 )  = trialdef ( :, 2 ) + trialpad;
        trialdefpad ( :, 3 )  = trialdef ( :, 3 ) - trialpad;
        
        % Gets the defined trials.
        fileconfig            = config;
        fileconfig.feedback   = 'no';
        fileconfig.trl        = trialdefpad;
        
        erfdata               = ft_redefinetrial ( fileconfig, wholedata );
        
        % Rewrites the data as 'single' to save memory.
        erfdata.trial         = cellfun ( @single, erfdata.trial, 'UniformOutput', false );
        
        
        fprintf ( 1, '    Filtering temporal data in the band %0.0f - %0.0f Hz.\n', config.erfband );
        
        % Generates a copy of the data filtered in the ERF band.
        fir                   = fir1 ( floor ( config.padding * wholedata.fsample ), config.erfband / ( wholedata.fsample / 2 ) );
        erfdata               = myft_filtfilt ( fir, 1, erfdata );
        
%         % Removes the padding.
%         cfg                   = [];
%         cfg.trl               = trialdef;
%         cfg.feedback          = 'no';
%         
%         erfdata               = ft_redefinetrial ( cfg, erfdata );
        
        % Removes the padding.
        erfdata               = myft_rmpad ( erfdata, config.padding );
        
        % Creates a dummy data with no channels for the artifact selection.
        cfg                   = [];
        cfg.channel           = [];
        cfg.feedback          = 'no';
        
        dummydata             = ft_selectdata ( cfg, erfdata );
        
        
        % Downsamples the ERF data to the Nyquist sampling rate.
        erfdata               = my_downsample ( erfdata, floor ( erfdata.fsample / 2 / config.erfband (2) ) );
        
        % Removes the 'cfg' field.
        erfdata               = rmfield ( erfdata, 'cfg' );
        
        % Rewrites the data as 'single' to save space.
        erfdata.trial         = cellfun ( @single, erfdata.trial, 'UniformOutput', false );
        
        
        fprintf ( 1, '    Calculating frequency data for the band %0.0f - %0.0f Hz.\n', config.freqband );
        
        % If needed, expands the trial definition to the segment size.
        trialdeffreq          = dummydata.sampleinfo;
        trialdeffreq ( :, 2 ) = max ( trialdeffreq ( :, 2 ), trialdeffreq ( :, 1 ) + fileconfig.segment * wholedata.fsample );
        trialdeffreq ( :, 3 ) = -cellfun ( @(x) sum ( x < 0 ), dummydata.time );
        fileconfig.trl        = trialdeffreq;
        
        freqdata              = ft_redefinetrial ( fileconfig, wholedata );
        clear wholedata
        
        cfg                   = [];
        cfg.method            = 'mtmfft';
        cfg.taper             = 'hamming';
        cfg.output            = 'fourier';
        cfg.foilim            = config.freqband;
        cfg.keeptrials        = 'yes';
        cfg.feedback          = 'no';
        
        freqdata              = ft_freqanalysis ( cfg, freqdata );
        
        % Removes the 'cfg' field.
        freqdata              = rmfield ( freqdata,  'cfg' );
        
        % Rewrites the data as 'single' to save space.
        freqdata.fourierspctrm = single ( freqdata.fourierspctrm );
        
        
        fprintf ( 1, '    Looking for artifacts in the data. ' );
        
        % Generates a dummy data for the artifact removal.
        cleandata              = dummydata;
        
        for cindex = 1: size ( config.crittoi, 1 )
            
            % Rejects the artifacts.
            cfg                   = [];
            cfg.artfctdef         = artinfo.artifact;
            cfg.artfctdef.crittoilim = config.crittoi ( cindex, : );
            cfg.feedback          = 'no';
            
            cleandata             = my_rejectartifact ( cfg, cleandata );
        end
        
        fprintf ( 1, '%i trials marked as artifacted.\n', numel ( dummydata.trial ) - numel ( cleandata.trial ) );
        
        % Marks the artifacted trials.
        trialtype             = single ( ~ismember ( dummydata.sampleinfo ( :, 1 ), cleandata.sampleinfo ( :, 1 ) ) );
        
        
        % Writes the trial's metadata.
        trialpad              = zeros ( numel ( erfdata.trial ), 1 );
        trialfile             = repmat ( findex,   numel ( erfdata.trial ), 1 );
        
        
        % Stores the epoch data.
        trialdefs  { findex } = trialdef;
        trialfiles { findex } = trialfile;
        trialpads  { findex } = trialpad;
        trialtypes { findex } = trialtype;
        erfdatas   { findex } = erfdata;
        freqdatas  { findex } = freqdata;
        
        clear dummydata
        clear erfdata
        clear freqdata
    end
    
    % Removes the empty files.
    empty                 = cellfun ( @isempty, erfdatas );
    
    erfdatas   ( empty )  = [];
    freqdatas  ( empty )  = [];
    
    trialdefs  ( empty )  = [];
    trialfiles ( empty )  = [];
    trialpads  ( empty )  = [];
    trialtypes ( empty )  = [];
    
    trialdef              = cat ( 1, trialdefs  {:} );
    trialfile             = cat ( 1, trialfiles {:} );
    trialpad              = cat ( 1, trialpads  {:} );
    trialtype             = cat ( 1, trialtypes {:} );
    
    clear trialdefs
    clear trialfiles
    clear trialpads
    clear trialtypes
    
    
    if isempty ( erfdatas )
        fprintf ( 1, '  No data for subject ''%s'' task ''%s''. Skipping.\n', taskinfo.subject, taskinfo.task );
        continue
    end
    
    fprintf ( 1, '  Merging all the data files.\n' );
    
    % Merges the epoch data.
    if numel ( erfdatas ) > 1
        
        % Merges the ERF.
        cfg           = [];
        
        erfdata       = myft_appenddata ( cfg, erfdatas  {:} );
        
        % Merges the frequency data.
        cfg.parameter = 'fourierspctrm';
        
        freqdata      = ft_appendfreq ( cfg, freqdatas {:} );
        
        % Removes the 'cfg' field.
        freqdata      = rmfield ( freqdata,  'cfg' );
    else
        
        erfdata       = erfdatas   {1};
        freqdata      = freqdatas  {1};
    end
    clear erfdatas
    clear freqdatas
    
    
    % Generates the trial information structure from the trial data.
    trialinfo             = [];
    trialinfo.trialdef    = trialdef;
    trialinfo.trialfile   = trialfile;
    trialinfo.trialpad    = trialpad;
    
    % Initilizes the clearn trials and components structure.
    cleaninfo             = [];
    cleaninfo.trial.types = { 'Clean trial' 'Noisy trial' };
    cleaninfo.trial.type  = trialtype;
    
    
    % Goes through each channel group.
    for chindex = 1: numel ( config.channel.groups )
        
        channel             = config.channel.groups { chindex };
        outname             = sprintf ( '%s%s_%s%s_%s.mat', config.path.sketch, taskinfo.subject, taskinfo.task, taskinfo.stage, channel );
        
        if exist ( outname, 'file' ) && ~config.overwrite
            fprintf ( 1, '  Ignoring channel group ''%s'' (already calculated).\n', channel );
            continue
        end
        
        if ~ismember ( channel, fieldnames ( taskinfo.compinfo.SOBI ) )
            fprintf ( 1, '  Ignoring channel group ''%s'' (no SOBI information).\n', channel );
            continue
        end
        
        fprintf ( 1, '  Saving channel group ''%s''.\n', channel );
        
        % Keeps only the selected channel group data.
        cfg                   = [];
        cfg.channel           = cat ( 2, { channel }, { 'EOG' 'ECG' 'EMG' } );
        
        grouperf              = ft_selectdata ( cfg, erfdata   );
        groupfreq             = ft_selectdata ( cfg, freqdata  );
        
        % Removes the 'cfg' field.
        grouperf              = rmfield ( grouperf,   'cfg' );
        groupfreq             = rmfield ( groupfreq,  'cfg' );
        
        % Keeps only the selected channel group SOBI information.
        compinfo              = taskinfo.compinfo;
        compinfo.SOBI         = taskinfo.compinfo.SOBI.( channel );
        
        % Adds the clean components to the information structure.
        cleaninfo.comp.types  = compinfo.types;
        cleaninfo.comp.type   = compinfo.SOBI.type;
        
        % Fills the group information.
        groupinfo             = [];
        groupinfo.subject     = taskinfo.subject;
        groupinfo.task        = taskinfo.task;
        groupinfo.stage       = taskinfo.stage;
        groupinfo.channel     = channel;
        groupinfo.fileinfo    = taskinfo.fileinfo;
        groupinfo.chaninfo    = taskinfo.chaninfo;
        groupinfo.artinfo     = taskinfo.artinfo;
        groupinfo.compinfo    = compinfo;
        groupinfo.trialinfo   = trialinfo;
        groupinfo.erfdata     = grouperf;
        groupinfo.freqdata    = groupfreq;
        groupinfo.cleaninfo   = cleaninfo;
        
        % Saves the current group epoch data.
        save ( '-v6', outname, '-struct', 'groupinfo' );
    end
end
