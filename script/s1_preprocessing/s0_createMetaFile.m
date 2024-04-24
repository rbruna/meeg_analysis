clc
clear
close all

infile   = '../../meta/eeg/times_';
outfile  = '../../meta/eeg/times.mat';


% Reads the file content.
fid      = fopen ( infile, 'r' );
text     = fread ( fid, [ 1 Inf ], '*char' );
fclose ( fid );

% Adds a new line at the end of the file.
text     = strcat ( text, newline );

% Replaces the carriage returns by new lines.
text     = strrep ( text, sprintf ( '\r' ),   newline );
% text     = strrep ( text, sprintf ( '\n\n' ), newline );
text     = regexprep ( text, sprintf ( '\n+' ), newline );

% Reads the data in the expected format.
lines    = textscan ( text, '%s %s %s %s %s %s\n' );

% Checks the length of the data.
if all ( cellfun ( @isempty, lines {6} ) )
    lines    = lines ( [ 1 2 6 3 4 5 ] );
end

subjects = lines {1};
tasks    = lines {2};
stages   = lines {3};
datasets = lines {4};
begtimes = num2cell ( str2double ( lines {5} ) );
endtimes = num2cell ( str2double ( lines {6} ) );

% Saves the values in structure form.
list    = struct ( 'dataset', datasets, 'subject', subjects, 'task', tasks, 'stage', stages, 'begtime', begtimes, 'endtime', endtimes );

% Saves the configuration structure.
save ( '-v6', outfile, 'list' )
