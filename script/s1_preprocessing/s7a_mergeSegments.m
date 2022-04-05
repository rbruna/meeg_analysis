clc
clear
close all

config.path.in   = '../../data/segments_split/';
config.path.out  = '../../data/segments/';
config.path.patt = '*.mat';

% Sets the action when the task have already been processed.
config.overwrite = false;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Creates and output folder, if needed.
if ~exist ( config.path.out, 'dir' ), mkdir ( config.path.out ); end

% Gets the list of files.
files = dir ( sprintf ( '%s%s', config.path.in, config.path.patt ) );

% Initializes the list of subjects and conditions.
infos     = struct ( 'subject', {}, 'task', {}, 'stage', {}, 'channel', {} );
infos ( numel ( files ) ).task = '';

% Goes through each file.
for findex = 1: numel ( files )
    
    % Gets the current file name.
    filename = files ( findex ).name;
    
    % Pre-loads the information.
    info     = load ( sprintf ( '%s%s', config.path.in, filename ), 'subject', 'task', 'stage', 'channel' );
    
    % Stores the information.
    infos ( findex ) = info;
end

% Gets the list of subjects and tasks.
subjects  = unique ( { infos.subject } );
tasks     = unique ( { infos.task    } );
stages    = unique ( { infos.stage   } );


% Goes through each subject.
for sindex = 1:numel ( subjects )
    
    % Gets the current cubject.
    subject   = subjects { sindex };
    
    % Goes though each task.
    for tindex = 1: numel ( tasks )
        
        % Gets the current task.
        task      = tasks { tindex };
        
        % Goes through each stage.
        for stindex = 1: numel ( stages )
            
            % Gets the current stage.
            stage     = stages { stindex };
            
            % Gets the message name of the subject-task-stage set.
            msgtext   = sprintf ( 'subject ''%s'', task ''%s''', subject, task );
            if ~isempty ( stage )
                msgtext   = sprintf ( '%s, stage ''%s''', msgtext, stage );
            end
            
            % Lists the channels.
            info      = infos ( strcmp ( { infos.subject }, subject ) & strcmp ( { infos.task }, task ) & strcmp ( { infos.stage }, stage ) );
            channels  = strjoin ( { info.channel }, '+' );
            
            if exist ( sprintf ( '%s%s_%s%s_%s.mat', config.path.out, subject, task, stage, channels ), 'file' ) && ~config.overwrite
                fprintf ( 1, 'Ignoring %s (already processed).\n', msgtext );
                continue
            end
            
            % Lists the files for the current subject and task.
            files = dir ( sprintf ( '%s%s_%s%s_%s', config.path.in, subject, task, stage, config.path.patt ) );
            
            if ~numel ( files )
                fprintf ( 1, 'Ignoring %s (no files found).\n', msgtext );
                continue
            end
            
            
            fprintf ( 1, 'Working with %s.\n', msgtext );
            
            % Reserves memory for the files.
            epochdatas = cell ( size ( files ) );
            
            % Loads all the files.
            for findex = 1: numel ( files )
                
                % Gets the current file name.
                filename = files ( findex ).name;
                
                % Preloads the file.
                info = load ( sprintf ( '%s%s', config.path.in, filename ), 'channel' );
                
                fprintf ( 1, '  Loading channel group ''%s''.\n', info.channel );
                
                % Loads the data.
                filedata = myft_load ( sprintf ( '%s%s', config.path.in, filename ) );
                
                % Stores the data.
                epochdatas { findex } = filedata;
            end
            
            % Joints all the files in an array of structures.
            epochdatas = cat ( 1, epochdatas {:} );
            
            
            % Gets the global information.
            epochdata           = [];
            epochdata.subject   = subject;
            epochdata.task      = task;
            epochdata.stage     = stage;
            epochdata.channel   = channels;
            epochdata.fileinfo  = epochdatas (1).fileinfo;
            epochdata.chaninfo  = epochdatas (1).chaninfo;
            epochdata.artinfo   = epochdatas (1).artinfo;
            
            % Adds dummy fields.
            epochdata.compinfo  = [];
            epochdata.trialinfo = [];
            epochdata.trialdata = [];
            
            % Adds the MRI information field, if existent.
            if isfield ( epochdatas, 'mriinfo' )
                epochdata.mriinfo   = epochdatas (1).mriinfo;
            end
            
            % Checks that all the files contain the same information.
            if numel ( files ) > 1
                fprintf ( 1, '  Checking the consistency of the data.\n' );
                
                if ~isequaln ( epochdatas.fileinfo ) || ~isequaln ( epochdatas.chaninfo ) || ~isequaln ( epochdatas.artinfo )
                    fprintf ( 1, '  The files contain different information. Ignoring.\n' );
                    continue
                end
            end
            
            
            fprintf ( 1, '  Rewriting the component information.\n' );
            
            % Goes through all the channel types.
            for gindex = 1: numel ( epochdatas )
                SOBI.( epochdatas ( gindex ).channel ) = epochdatas ( gindex ).compinfo.SOBI;
            end
            
            % Merges the component information.
            epochdata.compinfo.SOBI = SOBI;
            
            
            % If more than one file, merges the data.
            if numel ( files ) > 1
                
                fprintf ( 1, '  Merging the information into a single trial data.\n' );
                
                % Gets the trial information and data.
                trialinfos  = [ epochdatas.trialinfo ];
                trialdatas  = [ epochdatas.trialdata ];
                
                % Selects the trials present in all the channel groups.
                trialdef    = trialinfos (1).trialdef;
                for iindex = 2: numel ( trialinfos )
                    trialdef    = intersect ( trialdef, trialinfos ( iindex ).trialdef, 'rows' );
                end
                
                trials      = find ( ismember ( trialinfos (1).trialdef, trialdef, 'rows' ) );
                trialinfo.trialdef  = trialinfos (1).trialdef  ( trials );
                trialinfo.trialfile = trialinfos (1).trialfile ( trials );
                trialinfo.trialpad  = trialinfos (1).trialpad  ( trials );
                
                % Sanitizes the trial datas.
                for gindex = 1: numel ( epochdatas )
                    
                    % Selects only the required channels and trials.
                    cfg         = [];
                    cfg.channel = setdiff ( trialdatas ( gindex ).label, cat ( 1, trialdatas ( 1: gindex - 1 ).label ) );
                    cfg.trials  = find ( ismember ( trialinfos ( gindex ).trialdef, trialdef, 'rows' ) );
                    
                    trialdata   = ft_selectdata ( cfg, trialdatas ( gindex ) );
                    
                    % Removes the 'cfg' field and stores the result.
                    trialdata   = rmfield ( trialdata, 'cfg' );
                    trialdatas ( gindex ) = trialdata;
                end
                
                % Converts the array of structures in a cell of structures.
                trialdatas  = num2cell ( trialdatas );
                
                % Merges the trial datas.
                trialdata   = myft_appenddata ( [], trialdatas {:} );
                
                % Otherwise keeps the original data.
            else
                trialinfo   = epochdatas.trialinfo;
                trialdata   = epochdatas.trialdata;
            end
            
            % Reorders the channels in the original order.
            chorder     = my_matchstr ( trialdata.label, epochdata.fileinfo (1).header.label );
            chorder     = chorder ( isfinite ( chorder ) );
            trialdata.label = trialdata.label ( chorder );
            trialdata.trial = cellfun ( @(trial) trial ( chorder, : ), trialdata.trial, 'UniformOutput', false );
            
            
            fprintf ( 1, '  Saving the trial data.\n' );
            
            % Saves the data.
            epochdata.trialinfo = trialinfo;
            epochdata.trialdata = trialdata;
            
            myft_save ( sprintf ( '%s%s_%s%s_%s', config.path.out, epochdata.subject, epochdata.task, epochdata.stage, epochdata.channel ), epochdata );
        end
    end
end
