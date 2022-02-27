clc
clear
close all

% Sets the paths.
config.path.raw       = '../../data/tsss/';
config.path.out       = '../../meta/trl/';

% Action when the task has already been processed.
config.overwrite      = false;

% Defines the physiological channels(later will be relabeled).
config.physio.EOG     = { 'EEG061' };
config.physio.EKG     = { 'EEG062' };
config.physio.EMG     = {};


% The 'files' file is defined as a structure with fields:
% - dataset - File to load. Must be located in 'path.raw'.
% - subject - Subject label. Groups several files from the same subject.
% - task    - Task label. Only uses the selected task.
% - begtime - Begginning time of the segment (in seconds) or NaN (all the file).
% - endtime - Ending time of the segment (in seconds) or NaN (all the file).
%
% If no file definition is provided, 'patt' is the pattern that the files
% inside 'path.raw' must fulfill to be considered part of the data.
% 
% A regular expression can be provided to group files by subject and task.

config.path.files     = '../../meta/times.mat';

% Sets the regular expression to match {subject}, {task} and {stage}.
config.path.regexp    = '^(S[0-9]{2})_(task)().fif$';

% Otherwise sets the file pattern.
config.path.patt      = '*.fif';

% Sets the system configuration parameters.
config.task           = false;    % Task label to match.
config.stage          = false;    % Stage label to match.

% Sets the artifact detection parameters.
config.trialfun       = 'restingSegmentation';
config.segment        = 4;
config.padding        = 2;
config.addpadd        = true;
config.equal          = true;
config.precision      = 'single';
config.lookfor.eog    = true;
config.channel.eog    = { 'EOG' }; % Usually EEG061 for Elekta.
config.lookfor.jump   = true;
config.channel.jump   = { 'MEG' 'EEG' }; % MEG or MEGMAG for Elekta, MEG for 4D.
config.lookfor.muscle = true;
config.channel.muscle = { 'MEG' 'EEG' }; % MEG or MEGMAG for Elekta, MEG for 4D.
config.interactive    = 'no';


% Creates the output folder, if needed.
if ~exist ( config.path.out, 'dir' ), mkdir ( config.path.out ); end

% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% If files definition, loads the files defined there.
if config.path.files
    
    % Loads all the files.
    files    = struct2array ( load ( config.path.files ) );
    
% If no files definition and regular expression, matches the expression.
elseif config.path.regexp
    
    % Gets the list of filenames.
    hits     = dir ( sprintf ( '%s%s', config.path.raw, config.path.patt ) );
    hits     = { hits.name };
    
    % Search for the regular expression in the file names.
    meta     = regexp ( hits, config.path.regexp, 'tokens' );
    
    % Removes the files that do not match the regular expression.
    hits     = hits ( ~cellfun ( @isempty, meta ) );
    meta     = meta ( ~cellfun ( @isempty, meta ) );
    
    % Gets the information.
    datasets = hits;
    subjects = cellfun ( @(datum) datum {1} {1}, meta, 'UniformOutput', false );
    tasks    = cellfun ( @(datum) datum {1} {2}, meta, 'UniformOutput', false );
    stages   = cellfun ( @(datum) datum {1} {3}, meta, 'UniformOutput', false );
    
    % Constructs the files structure.
    files    = struct ( 'dataset', datasets, 'subject', subjects, 'task', tasks, 'stage', stages, 'begtime', NaN, 'endtime', NaN );
    
% Otherwise generates a files list with the raw folder and the template.
else
    
    % Gets the list of filenames.
    hits     = dir ( sprintf ( '%s%s', config.path.raw, config.path.patt ) );
    hits     = { hits.name };
    
    % The subject equals the dataset without the extension.
    datasets = hits;
    subjects = cellfun ( @(filename) regexprep ( filename, '.([^\.]+)$', '' ), hits, 'UniformOutput', false );
    
    
    % Constructs the files structure.
    tasks    = config.task;
    stages   = config.stage;
    files    = struct ( 'dataset', datasets, 'subject', subjects, 'task', tasks, 'stage', stages, 'begtime', NaN, 'endtime', NaN );
end

% Keeps only the files for the selected task, if requested.
if config.task
    files    = files ( strcmp ( { files.task }, config.task ) );
end


% Gets the list of subjects and tasks.
subjects = sort ( unique ( { files.subject } ) );
tasks    = sort ( unique ( { files.task    } ) );
stages   = sort ( unique ( { files.stage   } ) );

% Goes through all the subjects.
for sindex = 1: numel ( subjects )
    
    % Gets the subject label.
    subject = subjects { sindex };
    
    % Gets the list of files for the current subject.
    sfiles  = files ( strcmp ( { files.subject }, subject ) );
    
    fprintf ( 1, 'Working on subject ''%s''.\n', subject );
    
    
    % Goes through each task for the current subject.
    for tindex = 1: numel ( tasks )
        
        % Gets the task label.
        task      = tasks { tindex };
        
        % Goes through each stage.
        for stindex = 1: numel ( stages )
            
            % Gets the stage label.
            stage     = stages { stindex };
            
            % Gets the list of files for the current task and stage.
            tfiles    = sfiles ( strcmp ( { sfiles.task }, task ) &  strcmp ( { sfiles.stage }, stage ) );
            
            % If no files, skips this task-stage pair for the subject.
            if ~numel ( tfiles ), continue, end
            
            
            % Sets the output file name.
            outname   = sprintf ( '%s%s_%s%s.mat', config.path.out, subject, task, stage );
            
            % Gets the message name of the subject-task-stage set.
            msgtext   = sprintf ( 'task ''%s''', task );
            if ~isempty ( stage )
                msgtext   = sprintf ( '%s, stage ''%s''', msgtext, stage );
            end
            
            % Checks if the task has already been preprocessed.
            if exist ( outname, 'file' ) && ~config.overwrite
                fprintf ( 1, '  Ignoring %s (already calculated).\n', msgtext );
                continue
            end
            
            fprintf ( 1, '  Working on %s.\n', msgtext );
            
            % Reserves memory for the output structures.
            fileinfos = struct ( 'dataset', {}, 'subject', {}, 'task', {}, 'stage', {}, 'index', {}, 'begtime', {}, 'endtime', {}, 'header', {}, 'headshape', {}, 'event', {} );
            fileinfos ( numel ( tfiles ) ).subject = [];
            
            artinfos  = struct ( 'step', {}, 'date', {}, 'config', {}, 'artifact', {}, 'history', {} );
            artinfos  ( numel ( tfiles ) ).step = [];
            
            
            % Goes through each file.
            for findex = 1: numel ( tfiles )
                
                % Gets the file name.
                filename             = tfiles ( findex ).dataset;
                dataset              = sprintf ( '%s%s', config.path.raw, filename );
                begtime              = tfiles ( findex ).begtime;
                endtime              = tfiles ( findex ).endtime;
                
                % Checks the existence of the selected file.
                if ~exist ( dataset, 'file' )
                    fprintf ( 1, '    Ignoring file %i (file %s not found).\n', findex, filename );
                    continue
                end
                
                fprintf ( 1, '    Processing file %i (%s).\n', findex, filename );
                
                % Gets the dataset header, headshape and events.
                header               = my_read_header    ( dataset );
                event                = my_read_event     ( dataset, header );
                headshape            = my_read_headshape ( dataset, header );
                
                % Removes the data from the header.
                if isfield ( header.orig, 'data' )
                    header.orig.data     = [];
                end
                
                % Modifies, if required, the physiological data labels.
                oldlabel             = ft_channelselection ( config.physio.EOG, header.label );
                oldindex             = ismember ( header.label, oldlabel );
                header.label    ( oldindex ) = cellstr ( num2str ( ( 1: numel ( oldlabel ) )', 'EOG%03i' ) );
                header.chantype ( oldindex ) = { 'eog' };
                
                oldlabel             = ft_channelselection ( config.physio.EKG, header.label );
                oldindex             = ismember ( header.label, oldlabel );
                header.label    ( oldindex ) = cellstr ( num2str ( ( 1: numel ( oldlabel ) )', 'ECG%03i' ) );
                header.chantype ( oldindex ) = { 'ecg' };
                
                oldlabel             = ft_channelselection ( config.physio.EMG, header.label );
                oldindex             = ismember ( header.label, oldlabel );
                header.label    ( oldindex ) = cellstr ( num2str ( ( 1: numel ( oldlabel ) )', 'EMG%03i' ) );
                header.chantype ( oldindex ) = { 'emg' };
                
                
                % Sets the configuration for the current file.
                fileconfig           = config;
                fileconfig.dataset   = dataset;
                fileconfig.header    = header;
                fileconfig.begtime   = begtime;
                fileconfig.endtime   = endtime;
                fileconfig.fprintoff = 2;
                
                % Calls the manual artifact rejection function.
                artifact             = automaticArtifacts ( fileconfig );
                
                
                % Initializes the file info.
                fileinfo             = [];
                fileinfo.dataset     = dataset;
                fileinfo.subject     = subject;
                fileinfo.task        = task;
                fileinfo.stage       = stage;
                fileinfo.index       = findex;
                fileinfo.begtime     = begtime;
                fileinfo.endtime     = endtime;
                fileinfo.header      = header;
                fileinfo.headshape   = headshape;
                fileinfo.event       = event;
                
                % Initializes the epoch info.
                artinfo.current      = [];
                artinfo.history      = {};
                
                % Defines the current step structure.
                artinfo              = [];
                artinfo.step         = 'Automatic artifact detection';
                artinfo.date         = datestr ( now );
                artinfo.config       = config;
                artinfo.artifact     = artifact;
                artinfo.history      = {};
                
                % Adds the current step to the file history.
                current              = rmfield ( artinfo, 'history' );
                artinfo.history      = [ artinfo.history current ];
                
                % Stores the file information.
                fileinfos ( findex ) = fileinfo;
                artinfos  ( findex ) = artinfo;
            end
            
            % Removes the files with no data.
            if numel ( [ fileinfos.index ] ) ~= numel ( fileinfos )
                artinfos  ( cellfun ( @isempty, { fileinfos.index } ) ) = [];
                fileinfos ( cellfun ( @isempty, { fileinfos.index } ) ) = [];
            end
            
            % If no data for this task, goes to the next one.
            if numel ( fileinfos ) == 0
                if ~isempty ( stage )
                    fprintf ( 1, '    Ignoring task ''%s'', stage ''%s'' (no files found).\n', task, stage );
                else
                    fprintf ( 1, '    Ignoring task ''%s'' (no files found).\n', task );
                end
                continue
            end
            
            % Initializes the bad channels information.
            chaninfo.bad      = {};
            
            
            fprintf ( 1, '    Saving the task information.\n' );
            
            % Sets the task information.
            taskinfo          = [];
            taskinfo.subject  = subject;
            taskinfo.task     = task;
            taskinfo.stage    = stage;
            taskinfo.fileinfo = fileinfos;
            taskinfo.chaninfo = chaninfo;
            taskinfo.artinfo  = artinfos;
            
            % Saves the output data.
            save ( '-v6', outname, '-struct', 'taskinfo' );
        end
    end
end
