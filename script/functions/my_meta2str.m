function text = my_meta2str ( metadata, output )

% Convertes a metadata structure with fields subject, task, etc. into:
% * a text of the form "subject '<subject>', session '<session>',
%   task '<task>', ...".
% * a file name of the form "<subject>_<session>_<task>".
% * a file name in BIDS from "sub-<subject>_ses-<session>_task-<task>".

% As defaults, outputs the file name.
if nargin < 2
    output = 'filename';
end


% Replaces deprecated label "stage" by the new label "session".
if isfield ( metadata, 'stage' ), metadata.session = metadata.stage; end


% Defines the metadata fields of interest.
items   = { 'subject', 'session', 'task', 'channel' };

% Defines the preamble and postamble, if any.
switch lower ( output )
    case 'text'
        preams  = { 'subject ''', 'session ''', 'task ''', 'channel group ''' };
        postams = { '''', '''', '''', '''' };
    case 'filename'
        preams  = { '', '', '', '' };
        postams = { '', '', '', '' };
    case 'bids'
        preams  = { 'sub-', 'ses-', 'task-', 'chan-' };
        postams = { '', '', '', '' };
    otherwise
        error ( 'Invalid output format ''%s''', output )
end


% Prepares a cell array for all the recognized items.
texts = cell ( size ( items ) );

% Goes through each recognized item, in order.
for index = 1: numel ( items )

    % If no field, skips this item.
    if ...
        ~isfield ( metadata, items { index } ) || ...
        isempty ( metadata.( items { index } ) )
        continue
    end

    % Formats the text.
    texts { index } = sprintf ( '%s%s%s', ...
        preams { index }, ...
        metadata.( items { index } ), ...
        postams { index } );
end


% Keeps only the non-empty entries.
texts = texts ( ~cellfun ( @isempty, texts ) );

% Combines all the items.
if strcmpi ( output, 'text' )
    text = strjoin ( texts, ', ' );
else
    text = strjoin ( texts, '_' );
end
