clc
clear
close all

% Sets the paths.
config.path.bad  = '../../meta/bad/';
config.path.patt = '*.mat';
config.path.file = '../../meta/badchannels.mat';

% Creates the output folder, if required.
if ~exist ( fileparts ( config.path.file ), 'dir' ), mkdir ( fileparts ( config.path.file ) ); end


% Lists the files.
files = dir ( sprintf ( '%s%s', config.path.bad, config.path.patt ) );

% Initializes the file information variable.
fileinfos = cell ( numel ( files ), 1 );

% Loads all the files.
for findex = 1: numel ( files )
    
    fprintf ( 1, 'Working with file %s.\n', files ( findex ).name );
    
    % Loads the file information.
    fileinfo         = load ( sprintf ( '%s%s', config.path.bad, files ( findex ).name ) );
    
    % Removes the folder and the extension.
    [ ~, filename ]  = fileparts ( fileinfo.file );
    fileinfo.file    = filename;
    
    % Identifies the subject name.
    %fileinfo.subject = strtok ( fileinfo.file, '_' );
    fileinfo.subject = fileinfo.file;
    
    % Stores the information.
    fileinfos { findex } = fileinfo;
end

% Re-writes the file information into an array of structures.
fileinfos = cat ( 1, fileinfos {:} );


% Initializes the bad channel file.
badinfos = struct ( 'file', {}, 'bad', {}, 'trans', {} );
badinfos ( numel ( fileinfos ) ).file = [];

% Goes through each file.
for findex = 1: numel ( fileinfos )
    
    % Gets the first file from this subject.
    transinfo = fileinfos ( strcmp ( { fileinfos.subject } , fileinfos ( findex ).subject ) );
    transfile = transinfo (1).file;
    
    
    % Gets the acquision date.
    filedate  = fileinfos ( findex ).header.orig.meas_date (1);
    filedate  = datetime ( filedate, 'ConvertFrom', 'POSIX' );
    
    % Defines the calibration file using the acquisition date.
    if filedate >= datetime ( 2018, 9, 13 )
        calfile = '/neuro/databases/sss/sss_cal_3058_20180913.dat';
    else
        calfile = '/neuro/databases/sss/sss_cal_20120831.dat';
    end
    
    
    % Gets the MEG bad channels.
    badchan   = fileinfos ( findex ).bad;
    badchan   = badchan ( strncmp ( badchan, 'MEG', 3 ) );
    badchan   = strrep ( badchan, 'MEG', '' );
    badchan   = str2double ( badchan );
    
    % Stores the data for the current file.
    badinfos ( findex ).file  = fileinfos ( findex ).file;
    badinfos ( findex ).bad   = badchan;
    badinfos ( findex ).trans = transfile;
    badinfos ( findex ).cal   = calfile;
end

% Saves the bad channel information.
save ( '-v6', config.path.file, 'badinfos' );
