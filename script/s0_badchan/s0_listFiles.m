clc
clear
close all

% Sets the paths.
config.path.raw  = '../../data/raw/';
config.path.meta = '../../meta/bad/';
config.path.patt = '*.fif';

% Action when the task has already been processed.
config.overwrite = false;

% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Creates the output folder, if required.
if ~exist ( config.path.meta, 'dir' ), mkdir ( config.path.meta ); end

% Makes a deep look for files.
files  = my_deepfind ( config.path.raw, config.path.patt );

% Goes through each file.
for findex = 1: numel ( files )
    
    % (Nebre) Checks if the file already exists.
    if exist ( sprintf ( '%s%s.mat', config.path.meta, files ( findex ).name ), 'file' )&&~config.overwrite
        warning ( 'Ignoring %s (already extracted).', files ( findex ).name )
        continue
    end
    
    fprintf ( 1, 'Reading metadata from %s.\n', files ( findex ).name );
    
    % Defines the dataset.
    file   = sprintf ( '%s%s', files ( findex ).folder, files ( findex ).name );
    
    % Gets the file metadata.
    header = my_read_header ( file );
    event  = my_read_event  ( file, header );
    
    % Prepares the output.
    meta        = [];
    meta.file   = file;
    meta.header = header;
    meta.event  = event;
    meta.bad    = [];
    
    % Saves the data.
    save ( '-v6', sprintf ( '%s%s.mat', config.path.meta, files ( findex ).name ), '-struct', 'meta' )
end
