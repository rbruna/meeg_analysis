clc
clear
close all

% Sets the paths.
config.path.sketch      = '../../data/sketch/';
config.path.segs        = '../../data/segments_split/';
config.path.patt        = '*.mat';

% Sets the action when the task have already been processed.
config.overwrite        = false;

% Sets the component removal configuration parameters.
config.deEOG.perform    = true;
config.deEOG.filter     = 10;
config.deEOG.comptype   = 1;

config.deEKG.perform    = true;
config.deEKG.kalima     = false;
config.deEKG.comptype   = 2;

config.denoise.perform  = true;
config.denoise.comptype = 3;

% Sets the segment padding.
config.padding          = 2;

% Determines how the data must be stored (not used now).
config.fs               = 1000;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Creates and output folder, if needed.
if ~exist ( config.path.segs, 'dir' ), mkdir ( config.path.segs ); end


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
    cleanfile           = sprintf ( '%s%s', config.path.segs,   basename );
    
    % Loads the data.
    sketchdata          = load ( datafile, '-regexp', '^(?!erfdata|freqdata$).' );
    
    % Gets the message name of the subject-task-stage set.
    msgtext   = sprintf ( 'subject ''%s'', task ''%s''', sketchdata.subject, sketchdata.task );
    if ~isempty ( sketchdata.stage )
        msgtext   = sprintf ( '%s, stage ''%s''', msgtext, sketchdata.stage );
    end
    msgtext   = sprintf ( '%s, channel group ''%s''', msgtext, sketchdata.channel );
    
    if exist ( cleanfile, 'file' ) && ~config.overwrite
        fprintf ( 1, 'Ignoring %s (Already calculated).\n', msgtext );
        continue
    end
    
    fprintf ( 1, 'Cleaning data for %s.\n', msgtext );
    
    
    % Gets the data and component information.
    fileinfo            = sketchdata.fileinfo;
    trialinfo           = sketchdata.trialinfo;
    compinfo            = sketchdata.compinfo.SOBI;
    cleaninfo           = sketchdata.cleaninfo;
    
    
    % Removes the original padding, if any.
    padding             = round ( trialinfo.trialpad * fileinfo (1).header.Fs );
    trialinfo.trialdef ( :, 1: 3 ) = trialinfo.trialdef ( :, 1: 3 ) + [ -padding +padding -padding ];
    trialinfo.trialpad  = zeros ( size ( trialinfo.trialpad ) );
    
    % Adds the padding, if requested.
    if isfield ( config, 'padding' )
        padding             = round ( config.padding * fileinfo (1).header.Fs );
        trialinfo.trialdef ( :, 1: 3 ) = bsxfun ( @plus, trialinfo.trialdef ( :, 1: 3 ), [ -1 +1 -1 ] * padding );
        trialinfo.trialpad  = config.padding * ones ( size ( trialinfo.trialpad ) );
    end
    
    % Gets the data length of each file.
    headers             = cat ( 1, fileinfo.header );
    lengths             = cat ( 1, headers.nSamples );
    
    % Checks that the trial doesn't go over the edge of the file.
    trialover           = trialinfo.trialdef ( :, 1 ) < 0 | trialinfo.trialdef ( :, 2 ) > lengths ( trialinfo.trialfile );
    
    
    % Gets the list of clean trials.
    trialclean          = cleaninfo.trial.type == 0;
    
    % Loads the clean trials' information from any othe channel group.
    changroups = dir ( sprintf ( '%s%s_%s%s_*', config.path.sketch, sketchdata.subject, sketchdata.task, sketchdata.stage ) );
    for cindex = 1: numel ( changroups )
        
        % Loads the clean trials information.
        dummy = load ( sprintf ( '%s%s', config.path.sketch, changroups ( cindex ).name ), 'cleaninfo' );
        
        % Adds the bad trials to the list.
        trialclean = trialclean & ( dummy.cleaninfo.trial.type == 0 );
    end
    
    % Maks as invalid the overflown trials.
    trialclean          = trialclean & ~trialover;
    
    
    fprintf ( '  A total of %i trials marked as invalid.\n', sum ( ~trialclean ) );
    
    % Removes the artifacted or noisy trials.
    trialinfo.trialdef  = trialinfo.trialdef  ( trialclean, : );
    trialinfo.trialfile = trialinfo.trialfile ( trialclean, : );
    trialinfo.trialpad  = trialinfo.trialpad  ( trialclean, : );
    
    
    % Gets the offsets from the file headers with clean trials.
    dindexes            = unique ( trialinfo.trialfile );
    offsets             = cumsum ( cat ( 1, 0, headers.nSamples ) );
    
    % Modifies the trial definitions.
    trialdef            = trialinfo.trialdef;
    trialdef ( :, 1 )   = trialdef ( :, 1 ) + offsets ( trialinfo.trialfile );
    trialdef ( :, 2 )   = trialdef ( :, 2 ) + offsets ( trialinfo.trialfile );
    
    
    % Loads the whole files.
    wholedatas          = cell ( max ( dindexes ), 1 );
    for dindex = dindexes'
        
        fprintf ( 1, '  Loading data from file %i (%s).\n', dindex, fileinfo ( dindex ).dataset );
        
        % Loads the data.
        cfg                 = [];
        cfg.dataset         = fileinfo ( dindex ).dataset;
        cfg.header          = fileinfo ( dindex ).header;
        cfg.channel         = cat ( 2, { sketchdata.channel }, { 'EOG' 'ECG' 'EMG' } );
        
        wholedatas { dindex } = my_read_data ( cfg );
    end
    
    fprintf ( 1, '  Concatenating the data from all the files.\n' );
    
    % Removes the empty entries.
    wholedatas ( cellfun ( @isempty, wholedatas ) ) = [];
    
    if isempty ( wholedatas )
        fprintf ( 1, '  No valid data found. Ignoring.\n' );
        continue
    end
    
    % Joins the data.
    cfg                 = [];
    
    wholedata           = myft_appenddata ( cfg, wholedatas {:} );
    clear wholedatas
    
    % Corrects the sample information.
    wholedata.sampleinfo ( :, 1 ) = wholedata.sampleinfo ( :, 1 ) + offsets ( dindexes );
    wholedata.sampleinfo ( :, 2 ) = wholedata.sampleinfo ( :, 2 ) + offsets ( dindexes );
    
    
    fprintf ( 1, '  Segmenting the data using the trial definition.\n' );
    
    % Re-segments the data according to the trial definition.
    cfg                 = [];
    cfg.trl             = trialdef;
    cfg.feedback        = 'no';
    
    trialdata           = ft_redefinetrial ( cfg, wholedata );
    clear wholedata
    
    % Removes the 'cfg' and 'hdr' fields.
    trialdata           = rmfield ( trialdata, 'cfg' );
    trialdata           = rmfield ( trialdata, intersect ( fieldnames ( trialdata ), 'hdr' ) );
    
    % Rewrites the data as 'single' to save space.
    trialdata.trial     = cellfun ( @single, trialdata.trial, 'UniformOutput', false );
    
    
    fprintf ( 1, '  Calculating the component data.\n' );
    
    % Gets the component types.
    comptype            = cleaninfo.comp.type;
    
    % Gets the position of the channels needed for the components.
    compchans           = my_matchstr ( trialdata.label, compinfo.topolabel );
    
    % Gets the raw data in matrix form.
    rawdata             = cat ( 3, trialdata.trial {:} );
    
    % Gets the shape of the component data.
    compshape           = size ( rawdata );
    compshape (1)       = size ( compinfo.unmixing, 2 );
    
    % Gets the component data.
    rawcomp             = compinfo.unmixing * rawdata ( compchans, : );
    rawcomp             = reshape ( rawcomp, compshape );
    clear rawdata
    
    
    % Removes the EOG components.
    if config.deEOG.perform && any ( comptype == config.deEOG.comptype )
        
        fprintf ( 1, '    Cleaning the EOG components.\n' );
        
        % Gets the EOG components.
        EOGcomp = comptype == config.deEOG.comptype;
        EOGdata = rawcomp ( EOGcomp, :, : );
        
        % If selected, performs the filtered EOG removal.
        if any ( config.deEOG.filter )
            
            % Generates the filter.
            fir     = fir1 ( 200, config.deEOG.filter / ( trialdata.fsample / 2 ), 'high' );
            
            % Filters a permuted version of the EOG components.
            EOGdata = permute ( EOGdata, [ 2 1 3 ] );
            EOGdata = my_filtfilt ( fir, 1, EOGdata );
            EOGdata = permute ( EOGdata, [ 2 1 3 ] );
            
        % Otherwise sets the EOG components to zero.
        else
            EOGdata (:) = 0;
        end
        
        % Replaces the EOG components with the clean ones.
        rawcomp ( EOGcomp, :, : ) = EOGdata;
    end
    
    % Removes the EKG components.
    if config.deEKG.perform && any ( comptype == config.deEKG.comptype )
        
        fprintf ( 1, '    Cleaning the EKG components.\n' );
        
        % Gets the EKG components.
        EKGcomp = comptype == config.deEKG.comptype;
        EKGdata = rawcomp ( EKGcomp, :, : );
        
        % If selected, performs the KALIMA EKG removal.
        if config.deEKG.kalima
            
            if ~isfield ( cleaninfo, 'EKGlead' ) || isempty ( cleaninfo.EKGlead )
                fprintf ( 1, '      Ignoring (not EKG leading component/signal).\n' );
                
            else
                
                % Gets the raw data in matrix form.
                rawdata = cat ( 3, trialdata.trial {:} );
                
                % Extracts the EKG parts.
                EKGidx  = my_matchstr ( trialdata.label, cleaninfo.EKGlead.label );
                EKGpart = rawdata ( EKGidx, :, : );
                
                % Gets the EKG leading signal shape.
                leadshape = size ( EKGpart );
                leadshape (1) = 1;
                
                % Composes the EKG leading signal.
                EKGlead = cleaninfo.EKGlead.unmixing * EKGpart ( :, : );
                EKGlead = reshape ( EKGlead, leadshape );
                clear rawdata
                
                % Applies KALIMA to the data.
                EKGlead = permute ( EKGlead, [ 2 1 3 ] );
                EKGdata = permute ( EKGdata, [ 2 1 3 ] );
                EKGdata = kalima  ( EKGdata, EKGlead );
                EKGdata = permute ( EKGdata, [ 2 1 3 ] );
            end
            
        % Otherwise sets the EKG components to zero.
        else
            EKGdata (:) = 0;
        end
        
        % Replaces the EKG components with the clean ones.
        rawcomp ( EKGcomp, :, : ) = EKGdata;
    end
    
    % Removes the noisy components.
    if config.denoise.perform && any ( comptype == config.denoise.comptype )
        
        fprintf ( 1, '    Removing the noisy components.\n' );
        
        % Gets the noisy components.
        noisecomp = ( comptype == config.denoise.comptype );
        
        % Completely removes the noisy compents.
        rawcomp ( noisecomp, :, : ) = 0;
    end
    
    
    fprintf ( 1, '  Back-projecting the component data.\n' );
    
    % Reconstructs the time series from the clean component data.
    rawclean            = compinfo.mixing * rawcomp ( :, : );
    rawclean            = reshape ( rawclean, compshape );
    clear rawcomp
    
    
    % Gets the raw data in matrix form.
    rawdata             = cat ( 3, trialdata.trial {:} );
    
    % Replaces the affected time series in the original data.
    rawdata ( compchans, :, : ) = rawclean;
    clear rawclean
    
    % Replaces the original data for the clean one.
    trialdata.trial     = squeeze ( num2cell ( rawdata, [ 1 2 ] ) );
    clear rawdata
    
    
    % If any bad channel defined, removes them from the data.
    if ~isempty ( sketchdata.chaninfo.bad ) && ~isempty ( intersect ( sketchdata.chaninfo.bad, trialdata.label ) )
        
        % Removes the bad channels.
        cfg          = [];
        cfg.channel  = cat ( 1, { 'all' }, strcat ( '-', sketchdata.chaninfo.bad (:) ) );
        cfg.feedback = 'no';
        
        trialdata    = ft_preprocessing ( cfg, trialdata );
        
        % Removes the 'cfg' field.
        trialdata    = rmfield ( trialdata, 'cfg' );
    end
    
    
    fprintf ( 1, '  Saving the data.\n' );
    
    % Generates the output variable.
    epochdata           = [];
    epochdata.subject   = sketchdata.subject;
    epochdata.task      = sketchdata.task;
    epochdata.stage     = sketchdata.stage;
    epochdata.channel   = sketchdata.channel;
    epochdata.fileinfo  = sketchdata.fileinfo;
    epochdata.chaninfo  = sketchdata.chaninfo;
    epochdata.artinfo   = sketchdata.artinfo;
    epochdata.compinfo  = sketchdata.compinfo;
    epochdata.trialinfo = trialinfo;
    epochdata.trialdata = trialdata;
    
    % Saves the data.
    myft_save ( sprintf ( '%s%s', config.path.segs, basename ), epochdata );
end
