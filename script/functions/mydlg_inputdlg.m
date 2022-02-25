function output = myinputdlg ( texts, title, lines, defaults, options )
%INPUTDLG Input dialog box.
%
%  ANSWER = INPUTDLG(PROMPT) creates a modal dialog box that returns user
%  input in the string ANSWER. PROMPT string containing the PROMPT to show.
%
%  INPUTDLG uses UIWAIT to suspend execution until the user responds.
%
%  ANSWER = INPUTDLG(PROMPT,NAME) specifies the title for the dialog.
%  
%  This function improoves the Matlab original one by confirming the input
%  at the pressing of the 'Return' key. Pressing the 'Escape' key will
%  cancel the input.

% Generates an error if the number of arguments is incorrect.
narginchk  ( 0, 5 );
nargoutchk ( 0, 1 );


% Fulfills the arguments.
if nargin < 1,            texts    = 'Input:';     end
if nargin < 2,            title    = 'Question';   end
if nargin < 3,            lines    = [ 1 10 ];     end
if nargin < 4,            defaults = '';           end
if nargin < 5,            options  = struct ();    end

% Converts the text and default answer to cell arrays.
if ~iscell ( texts ),     texts    = { texts };    end
if ~iscell ( defaults ),  defaults = { defaults }; end

% If there is only one default answer, replicates it as needed.
if isscalar ( defaults ), defaults = repmat ( defaults, size ( texts ) ); end

% Converts the texts and the defaults in column cell arrays.
texts    = texts    (:);
defaults = defaults (:);

% If lines is a vector, second element is length.
if numel ( lines ) > 1
    columns = lines (2);
    lines   = lines (1);
else
    columns = 10;
end


% Checks the options.
if ischar ( options ), options = struct ( 'Resize', options ); end

% Checks the arguments.
if ~iscellstr ( texts ),    error ( 'This function only accepts strings or cell strings as its first parameter.' ),        end
if ~ischar    ( title ),    error ( 'This function only accepts strings as its second parameter.' ),                       end
if ~isnumeric ( lines ),    error ( 'This function only accepts intergers as it third parameter.' ),                end
if ~iscellstr ( defaults ), error ( 'This function only accepts strings or cell strings as its fourth parameter.' ),       end
if ~isstruct  ( options ),  error ( 'This function only accepts strings or structs as its fifth parameter.' ),             end

if numel ( texts ) ~= numel ( defaults ), error ( 'The number of default answers do not match the number of questions.' ); end

% Fulfills the options.
if ~isfield ( options, 'Resize' ),      options.Resize =      'off';    end
if ~isfield ( options, 'WindowStyle' ), options.WindowStyle = 'normal'; end
if ~isfield ( options, 'Interpreter' ), options.Interpreter = 'none';   end


% Stores the inputs in the configuration field.
handles.config.texts    = texts;
handles.config.title    = title;
handles.config.lines    = lines;
handles.config.columns  = columns;
handles.config.defaults = defaults;
handles.config.options  = options;

% Initializes the output.
handles.output = {};


% Creates the empty figure.
handles.dialog = figure ( ...
    'Units',            'pixels', ...
    'Position',         [ 597 455 175 87 ], ...
    'Color',            [ 0.9 0.9 0.9 ], ...
    'Menubar',          'none', ...
    'Numbertitle',      'off', ...
    'Name',             title, ...
    'CloseRequestFcn',  'uiresume', ...
    'Resize',           options.Resize, ...
    'HandleVisibility', 'off', ...
    'WindowStyle',      options.WindowStyle, ...
    'Visible',          'off' );

% Creates as many text fields as questions.
for item = 1: numel ( texts )
    
    handles.text ( item ) = uicontrol ( ...
        'Style',               'text', ...
        'Units',               'pixels', ...
        'BackgroundColor',     [ 0.9 0.9 0.9 ], ...
        'Position',            [ 5 62 165 15 ], ...
        'HorizontalAlignment', 'left', ...
        'String',              texts { item }, ...
        'Parent',              handles.dialog );
end

% Creates as many edit fields as answers.
for item = 1: numel ( defaults )
    
    handles.edit ( item ) = uicontrol ( ...
        'Style',               'edit', ...
        'Units',               'pixels', ...
        'Max',                 lines, ...
        'BackgroundColor',     [ 1 1 1 ], ...
        'Position',            [ 5 38 5 8 ] + 16 * [ 0 0 columns lines ], ...
        'HorizontalAlignment', 'center', ...
        'String',              defaults { item }, ...
        'Parent',              handles.dialog );
end

% Creates the buttons.
handles.ok = uicontrol ( ...
    'Style',   'pushbutton', ...
    'Units',    'pixels', ...
    'Position', [ 57 5 54 28 ], ...
    'String',   'OK', ...
    'Parent',   handles.dialog );

handles.cancel = uicontrol ( ...
    'Style',    'pushbutton', ...
    'Units',    'pixels', ...
    'Position', [ 116 5 54 28 ], ...
    'String',   'Cancel', ...
    'Callback', 'uiresume', ...
    'Parent',   handles.dialog );


% Sets the recomended size for each text.
for item = 1: numel ( texts )
    [ aux1, aux2 ] = textwrap ( handles.text ( item ), texts ( item ), numel ( texts { item } ) + 1 );
    set ( handles.text ( item ), 'String', aux1, 'Position', aux2 );
end

% Gets the position of the uicontrols.
windowpos = get ( 0,              'ScreenSize' );
dialogpos = get ( handles.dialog, 'Position' );
textpos   = get ( handles.text,   'Position' );
editpos   = get ( handles.edit,   'Position' );
okpos     = get ( handles.ok,     'Position' );
cancelpos = get ( handles.cancel, 'Position' );

if ~iscell ( textpos ), textpos = { textpos }; end
if ~iscell ( editpos ), editpos = { editpos }; end

% Sets the default width as the maximum of the widths.
maxwidth  = max ( cellfun ( @(x) x (3), [ textpos; editpos ] ) );


% Places all the elements starting at the bottom.

% Places the buttons in the bottom.
okpos     (1) = maxwidth + 5 - cancelpos (3) - 5 - okpos (3);
cancelpos (1) = maxwidth + 5 - cancelpos (3);

% Sets the new positions.
set ( handles.ok,     'Position', okpos );
set ( handles.cancel, 'Position', cancelpos );

% Sets the original y-offset.
offset    = 5 + okpos (4) + 5;


% Goes through all the questions.
for item = numel ( defaults ): -1: 1
    
    % Places the edit box at the offset plus 5 pixels.
    editpos { item } (1) = 5;
    editpos { item } (2) = offset + 5;
    editpos { item } (3) = maxwidth;
    
    % Places the text over the edit box.
    textpos { item } (1) = 5;
    textpos { item } (2) = offset + 5 + editpos { item } (4);
    textpos { item } (3) = maxwidth;
    
    % Sets the new positions.
    set ( handles.edit ( item ), 'Position', editpos { item } );
    set ( handles.text ( item ), 'Position', textpos { item } );
    
    % Updates the y-offset.
    offset = offset + 5 + editpos { item } (4) + 5 + textpos { item } (4);
end

% Sets the dialog size.
dialogpos (3) = 5 + maxwidth + 5;
dialogpos (4) = offset + 5;

% Places the dialog in the center of the screen.
dialogpos (1) = ( windowpos (3) - dialogpos (3) ) / 2;
dialogpos (2) = ( windowpos (4) - dialogpos (4) ) / 2;

set ( handles.dialog, 'Position', dialogpos );


% Sets the callbacks.
set ( handles.ok,     'Callback',        { @okpress } )
set ( handles.cancel, 'Callback',        { @cancelpress } )
set ( handles.dialog, 'CloseRequestFcn', { @cancelpress } )
set ( handles.edit,   'KeyPressFcn',     { @keypress } )

% Shows the dialog.
set ( handles.dialog, 'Visible', 'on', 'HandleVisibility', 'off' );
guidata ( handles.dialog, handles );

% Sets the active field and pauses execution.
uicontrol ( handles.edit (1) )
uiwait    ( handles.dialog )

% Loads the stored data.
handles = guidata ( handles.dialog );

% Outputs the string and exits.
output = handles.output;
delete ( handles.dialog );


function okpress ( hObject, varargin )

% Gets the handles data.
handles = guidata ( hObject );

% Sets the value for the output and saves it.
handles.output = cellstr ( get ( handles.edit, 'String' ) );
guidata ( hObject, handles );

% Continues with the execution.
uiresume ( handles.dialog )


function cancelpress ( hObject, varargin )

% Gets the handles data.
handles = guidata ( hObject );

% Continues with the execution.
uiresume ( handles.dialog )


function keypress ( hObject, eventdata )

% Gets the handles data.
handles = guidata ( hObject );

% Updates the input data.
drawnow

% Checks the pressed key.
switch lower ( eventdata.Key )
    
    % If the key is Return, saves.
    case 'return'
        if handles.config.lines == 1, okpress ( hObject ), end
        
    % If the key is Escape, exits.
    case 'escape'
        uiresume ( handles.dialog )
end
