clc
clear
close all

% Sets the paths.
config.path.trl       = '../../meta/trl/';
config.path.patt      = '*.mat';

% Sets the visualization configuration parameters.
config.trialfun       = 'restingSegmentation';
config.segment        = 20;
config.overlap        = 10;
config.equal          = false;
config.padding        = 2;
config.addpadd        = false;

config.channel.data   = { 'MEG' 'EEG' };
config.channel.ignore = {};

% Sets the filter band.
config.filter.band    = [ 2 45 ];

% Sets the events to show (Inf for all).
config.event          = Inf;


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
    filename            = sprintf ( '%s%s', config.path.trl, filename );
    
    % Loads the current task information.
    taskinfo            = load ( filename );
    
    % Gets the message name of the subject-task-stage set.
    msgtext   = sprintf ( 'subject ''%s'', task ''%s''', taskinfo.subject, taskinfo.task );
    if ~isempty ( taskinfo.stage )
        msgtext   = sprintf ( '%s, stage ''%s''', msgtext, taskinfo.stage );
    end
    
    fprintf ( 1, 'Working on %s.\n', msgtext );
    
    % Gets the files length as a vector.
    headers             = [ taskinfo.fileinfo.header ];
    samples             = [ headers.nSamples ];
    offsets             = cat ( 2, 0, cumsum ( samples) );
    
    % Calculates the optimal downsampling rate for the frequency band.
    downrate            = floor ( headers (1).Fs / ( 2 * config.filter.band ( end ) ) );
    offsets             = ceil  ( offsets / downrate );
    
    % Calculates the optimal filter order from the desired padding.
    filtorder           = floor ( headers (1).Fs * config.padding );
    
    
    % Reserves memory for the trialdata and the artifact definitions.
    trialdatas          = cell ( numel ( taskinfo.fileinfo ), 1 );
    events              = cell ( numel ( taskinfo.fileinfo ), 1 );
    artifacts           = cell ( numel ( taskinfo.fileinfo ), 1 );
    
    % Goes through all the data files.
    for findex = 1: numel ( taskinfo.fileinfo )
        
        % Gets the current epochs and artifact definitions.
        fileinfo             = taskinfo.fileinfo ( findex );
        artinfo              = taskinfo.artinfo  ( findex );
        
        [ ~, name, ext ]     = fileparts ( taskinfo.fileinfo ( findex ).dataset );
        basename             = strcat ( name, ext );
        
        if ~exist ( fileinfo.dataset, 'file' )
            fprintf ( 1, '  Ignoring file %i (file %s not found).\n', findex, basename );
            continue
        end
        
        fprintf ( 1, '  Processing file %i (%s).\n', findex, basename );
        
        fprintf ( 1, '    Reading data from disk.\n' );
        
        % Gets the MEG data.
        cfg                  = [];
        cfg.dataset          = fileinfo.dataset;
        cfg.header           = fileinfo.header;
        
        wholedata            = my_read_data ( cfg );
        
        % Selects the channels.
        cfg                  = [];
        cfg.channel          = cat ( 2, config.channel.data, { 'EOG' 'ECG' }, strcat ( '-', config.channel.ignore ) );
        cfg.precision        = 'single';
        cfg.feedback         = 'no';
        
        wholedata            = ft_preprocessing ( cfg, wholedata );
        
        
        fprintf ( 1, '    Filtering the data in the band %0.0f - %0.0f Hz.\n', config.filter.band );
        
        % Filters and downsamples the data.
        fir                  = fir1 ( filtorder, config.filter.band / ( wholedata.fsample / 2 ) );
        wholedata            = myft_filtfilt ( fir, 1, wholedata );
        wholedata            = my_downsample ( wholedata, downrate );
        
        
        % Extracts the overlapping epochs for the artifact revision.
        trialfun             = str2func ( config.trialfun );
        
        fileconfig           = config;
        fileconfig.dataset   = fileinfo.dataset;
        fileconfig.header    = wholedata.hdr;
        fileconfig.begtime   = fileinfo.begtime;
        fileconfig.endtime   = fileinfo.endtime;
        fileconfig.feedback  = 'no';
        
        fileconfig.channel.bad = taskinfo.chaninfo.bad;
        
        fileconfig.trl       = trialfun ( fileconfig );
        
        trialdata            = ft_redefinetrial ( fileconfig, wholedata );
        clear wholedata;
        
        % Removes the 'cfg' field.
        trialdata            = rmfield ( trialdata, 'cfg' );
        
        trialdata.trial      = cellfun ( @single, trialdata.trial, 'UniformOutput', false );
        
        % Corrects the sample information of the trials.
        trialdata.sampleinfo = trialdata.sampleinfo + offsets ( findex );
        
        % Resamples and corrects the events definitions.
        event                = fileinfo.event (:);
        
        if numel ( event )
            [ event.sample ]      = my_deal ( ceil ( [ event.sample ] / downrate ) );
            [ event.sample ]      = my_deal ( [ event.sample ] + offsets ( findex ) );
        end
        
        % Resamples and corrects the artifact definitions.
        artifact              = artinfo.artifact;
        arttypes              = fieldnames ( artifact );
        
        for aindex = 1: numel ( arttypes )
            arttype                       = arttypes { aindex };
            artifact.( arttype ).artifact = ceil ( artifact.( arttype ).artifact / downrate );
            artifact.( arttype ).artifact = artifact.( arttype ).artifact + offsets ( findex );
        end
        
        
        % Stores the epoch data.
        trialdatas  { findex } = trialdata;
        events      { findex } = event;
        artifacts   { findex } = artifact;
    end
    
    fprintf ( 1, '  Merging all the data files.\n' );
    
    % Merges the epoch data.
    cfg                 = [];
    
    trialdata           = myft_appenddata ( cfg, trialdatas {:} );
    clear trialdatas
    
    % Merges the event information.
    event               = cat ( 1, events {:} );
    
    % Merges the artifact definitions.
    artifact            = [];
    arttypes            = fieldnames ( artifacts {1} );
    
    for aindex = 1: numel ( arttypes )
        arttype                       = arttypes { aindex };
        dummy                         = cellfun ( @(x) x.( arttype ).artifact, artifacts, 'UniformOutput', false );
        artifact.( arttype ).artifact = cat ( 1, dummy {:} );
    end
    
    % Removes the undesired events, if requested.
    if config.event < Inf
        event               = event ( ismember ( [ event.value ], config.event ) );
    end
    
    
    fprintf ( 1, '  Combining the components for all channel groups.\n' );
    
    % Selects the SOBI components for the last step.
    SOBI                = taskinfo.compinfo.SOBI;
    
    % Combines the components for all the chanel types.
    channels            = fieldnames ( SOBI );
    comptypes           = cell ( numel ( channels ), 1 );
    compposs            = cell ( numel ( channels ), 1 );
    topolabels          = cell ( numel ( channels ), 1 );
    unmixings           = cell ( numel ( channels ), 1 );
    mixings             = cell ( numel ( channels ), 1 );
    EOGcomps            = cell ( numel ( channels ), 1 );
    EKGcomps            = cell ( numel ( channels ), 1 );
    
    % Goes through each channel type.
    for chindex = 1: numel ( channels )
        
        channel                = channels { chindex };
        
        % Gets the values for the current channel type.
        comptypes  { chindex } = chindex * ones ( numel ( SOBI.( channel ).topolabel ), 1 );
        compposs   { chindex } = ( 1: numel ( SOBI.( channel ).topolabel ) )';
        topolabels { chindex } = SOBI.( channel ).topolabel;
        mixings    { chindex } = SOBI.( channel ).mixing;
        unmixings  { chindex } = SOBI.( channel ).unmixing;
        
        % Gets the values for the rejected components.
        if isfield ( SOBI.( channel ), 'type' )
            EOGcomps { chindex } = find ( SOBI.( channel ).type == 1 );
            EOGcomps { chindex } = cat ( 2, chindex * ones ( size ( EOGcomps { chindex } ) ), EOGcomps { chindex } );
            
            EKGcomps { chindex } = find ( SOBI.( channel ).type == 2 );
            EKGcomps { chindex } = cat ( 2, chindex * ones ( size ( EKGcomps { chindex } ) ), EKGcomps { chindex } );
        else
            EOGcomps { chindex } = zeros ( 0, 2 );
            EKGcomps { chindex } = zeros ( 0, 2 );
        end
    end
    
    % Concatenates the matrices.
    comptype            = cat     ( 1, comptypes  {:} );
    comppos             = cat     ( 1, compposs   {:} );
    topolabel           = cat     ( 1, topolabels {:} );
    mixing              = blkdiag ( mixings       {:} );
    unmixing            = blkdiag ( unmixings     {:} );
    EOGcomp             = cat     ( 1, EOGcomps   {:} );
    EKGcomp             = cat     ( 1, EKGcomps   {:} );
    
    % Tries to sort the components.
    %%% TO DO
    
    
    fprintf ( 1, '  Removing the artifact components.\n' );
    
    % Calculates the position of the current EOG and EKG components.
    EOGcomp             = find ( ismember ( [ comptype comppos ], EOGcomp, 'rows' ) );
    EKGcomp             = find ( ismember ( [ comptype comppos ], EKGcomp, 'rows' ) );
    
    % Gets the components for all the channel types at once.
    cfg = [];
    cfg.topolabel       = topolabel;
    cfg.mixing          = mixing;
    cfg.unmixing        = unmixing;
    cfg.updatesens      = 'no';
    cfg.demean          = 'no';
    cfg.doscale         = 'no';
    cfg.feedback        = 'no';
    
    compdata            = ft_componentanalysis ( cfg, trialdata );
    compdata.grad       = [];
    compdata.elec       = [];
    
    % Corrects the topology maps using the original mixing matrix.
    for mychan = 1: numel ( topolabel )
        
        ftchan = strcmp ( compdata.topolabel, topolabel { mychan } );
        
        mytopo = mixing ( mychan, : );
        compdata.topo ( ftchan, : ) = mytopo;
    end
    
    % Removes the artifact components.
    cfg.component       = cat ( 1, EOGcomp, EKGcomp );
    cleandata           = ft_rejectcomponent ( cfg, compdata, trialdata );
    
    
    
    
    
%     % Gets the distance from each sensor to the eyes.
%     distance1           = sqrt ( sum ( ( bsxfun ( @minus, trialdata.grad.chanpos, trialdata.grad.chanpos ( find ( strcmp ( trialdata.grad.label, 'MEG0121' ), 1 ), : ) ) ) .^ 2, 2 ) );
%     distance2           = sqrt ( sum ( ( bsxfun ( @minus, trialdata.grad.chanpos, trialdata.grad.chanpos ( find ( strcmp ( trialdata.grad.label, 'MEG1411' ), 1 ), : ) ) ) .^ 2, 2 ) );
%     distance            = min ( distance1, distance2 );
%     
%     % Sorts the channels according to the distance to the nasion.
%     [ ~, order ]        = sort ( distance );
%     
%     % Appends the non-MEG channels.
%     order               = cat ( 1, order, 307, 308 );
%     
%     % Reorders the data.
%     cleandata           = my_orderchans ( cleandata, order );
    
    
    
    
    
    
    % Gets the list of non-MEG channels (EOG, EKG, etc.).
    MEG                 = find ( ismember ( cleandata.label', ft_channelselection ( { 'MEG' },             cleandata.label ) ) );
    MEGMAG              = find ( ismember ( cleandata.label', ft_channelselection ( { 'MEGMAG' },          cleandata.label ) ) );
    MEGGRAD             = find ( ismember ( cleandata.label', ft_channelselection ( { 'MEGGRAD' },         cleandata.label ) ) );
    EEG                 = find ( ismember ( cleandata.label', ft_channelselection ( { 'EEG' },             cleandata.label ) ) );
    physio              = find ( ismember ( cleandata.label', ft_channelselection ( { 'EOG' 'ECG' 'EMG' }, cleandata.label ) ) );
    
    % Sets the colors according to the channel type.
    chancol             = zeros ( numel ( cleandata.label ), 1 );
    chancol ( MEG )     = 1;
    chancol ( MEGMAG )  = 2;
    chancol ( MEGGRAD ) = 3;
    chancol ( EEG )     = 4;
    chancol ( physio )  = 5;
    
    % Defines the EEG projector.
    projector           = [];
    projector.kind      = 10; % EEG average reference.
    projector.active    = true;
    projector.desc      = 'EEG average reference';
    projector.data      = [];
    projector.data.nrow      = 1;
    projector.data.ncol      = sum ( EEG );
    projector.data.row_names = [];
    projector.data.col_names = trialdata.label ( EEG );
    projector.data.data      = ones ( 1, sum ( EEG ) );
    
    % Displays the MEG data to append or remove artifacts.
    cfg                 = [];
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
    
    cfg.badchan         = fileconfig.channel.bad;
    cfg.projinfo        = projector;
    cfg.applyprojector  = true;
    
    cfg                 = my_databrowser ( cfg, cleandata );
    drawnow
    
    % Goes through all the data files.
    for findex = 1: numel ( taskinfo.artinfo )
        
        % Uses the full list of artifacts.
        artifact        = cfg.artfctdef;
        
        % Gets the previous step artifact definition.
        artinfo         = taskinfo.artinfo ( findex );
        
        % Gets the number of previous and current samples.
        psamples        = sum ( [ headers( 1: findex - 1 ).nSamples ] );
        csamples        = headers( findex ).nSamples;
        
        % Corrects the artifact definitions.
        arttypes = fieldnames ( artifact );
        for aindex = 1: numel ( arttypes )
            
            % Gets the list of artifacts of the current type.
            arttype         = arttypes { aindex };
            artifact        = cfg.artfctdef.( arttype ).artifact;
            
            % Resamples and corrects the artifact definitions.
            artifact        = artifact * downrate;
            artifact        = artifact - psamples;
            
            % Removes the artifacts of previous files.
            artifact ( artifact ( :, 2 ) < 1,        : ) = [];
            
            % Removes the artifacts of future files.
            artifact ( artifact ( :, 1 ) > csamples, : ) = [];
            
            % Corrects the first and last artifact, if needed.
            artifact        = max ( artifact, 1 );
            artifact        = min ( artifact, csamples );
            
            % Stores the current artifact definition.
            artinfo.artifact.( arttype ).artifact = artifact;
        end
        
        % Updates the current step structure.
        artinfo.step    = 'Post-IC removal EOG artifact revision';
        artinfo.date    = datestr ( now );
        
        % Adds the current step to the file history.
        current         = rmfield ( artinfo, 'history' );
        artinfo.history = [ artinfo.history current ];
        
        taskinfo.artinfo ( findex ) = artinfo;
    end
    
    % Saves the output data.
    save ( '-v6', filename, '-struct', 'taskinfo' )
end
