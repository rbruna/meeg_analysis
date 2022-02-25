function output = myquestdlg ( text, title, btn1, btn2, btn3, default, options )


% Generates an error if the number of arguments is incorrect.
narginchk  ( 0, 7 );
nargoutchk ( 0, 1 );

% Gest the options.
mynargin = nargin;
if mynargin < 7, options = struct (); end

if mynargin == 6 && isstruct ( default )
    options  = default;
    default  = '';
    mynargin = 5;
end
if mynargin == 5 && isstruct ( btn3 )
    options  = btn3;
    btn3     = '';
    mynargin = 4;
end
if mynargin == 4 && isstruct ( btn2 )
    options  = btn2;
    btn3     = '';
    mynargin = 3;
end
if mynargin == 3 && isstruct ( btn1 )
    options  = btn1;
    btn3     = '';
    mynargin = 2;
end

% Fulfills the arguments.
if mynargin == 5, default = btn3;      end
if mynargin == 5, btn3    = btn2;      end
if mynargin == 5, btn2    = btn1;      end
if mynargin == 5, btn1    = '';        end
if mynargin == 4, default = btn2;      end
if mynargin == 4, btn3    = btn1;      end
if mynargin == 4, btn2    = '';        end
if mynargin == 4, btn1    = '';        end
if mynargin == 3, default = btn1;      end
if mynargin == 3, btn3    = btn1;      end
if mynargin == 3, btn2    = '';        end
if mynargin == 3, btn1    = '';        end
if mynargin <  3, default = 'Yes';     end
if mynargin <  3, btn3    = 'Cancel';  end
if mynargin <  3, btn2    = 'No';      end
if mynargin <  3, btn1    = 'Yes';     end
if mynargin <  2, title   = '';        end
if mynargin <  1, text    = 'Input:';  end

% Checks the arguments.
if ~ischar   ( text ),    error ( 'This function only accepts strings as its first parameter.' ),             end
if ~ischar   ( title ),   error ( 'This function only accepts strings as its second parameter.' ),            end

% Checks that the default option is valid.
if     strcmp ( default, btn3 ), default = 'btn3';
elseif strcmp ( default, btn2 ), default = 'btn2';
elseif strcmp ( default, btn1 ), default = 'btn1';
else   error  ( 'The default string is not valid' );
end

% Fulfills the options.
if ~isfield  ( options, 'Resize' ),      options.Resize =      'off';    end
if ~isfield  ( options, 'WindowStyle' ), options.WindowStyle = 'normal'; end
if ~isfield  ( options, 'Interpreter' ), options.Interpreter = 'none';   end

% Initializes the output.
handles.output = '';

% Creates the objects.
handles.dialog = figure ( ...
    'Units', 'pixels', ...
    'Position', [ 597 455 175 87 ], ...
    'Color', [ 0.9 0.9 0.9 ], ...
    'Menubar', 'none', ...
    'Numbertitle', 'off', ...
    'Name', title, ...
    'CloseRequestFcn', 'uiresume', ...
    'Resize', options.Resize, ...
    'HandleVisibility', 'off', ...
    'WindowStyle', options.WindowStyle, ...
    'Visible', 'off' );

handles.text = uicontrol ( ...
    'Style', 'text', ...
    'Units', 'pixels', ...
    'BackgroundColor', [ 0.9 0.9 0.9 ], ...
    'Position', [ 5 62 165 15 ], ...
    'HorizontalAlignment', 'left', ...
    'String', text, ...
    'Parent', handles.dialog );

handles.btn1 = uicontrol ( ...
    'Style', 'pushbutton', ...
    'Units', 'pixels', ...
    'Position', [ -2 5 54 28 ], ...
    'String', btn1, ...
    'UserData', btn1, ...
    'Parent', handles.dialog );

if ~numel ( btn1 ), set ( handles.btn1, 'Visible', 'off' ); end

handles.btn2 = uicontrol ( ...
    'Style', 'pushbutton', ...
    'Units', 'pixels', ...
    'Position', [ 57 5 54 28 ], ...
    'String', btn2, ...
    'UserData', btn2, ...
    'Parent', handles.dialog );

if ~numel ( btn2 ), set ( handles.btn2, 'Visible', 'off' ); end

handles.btn3 = uicontrol ( ...
    'Style', 'pushbutton', ...
    'Units', 'pixels', ...
    'Position', [ 116 5 54 28 ], ...
    'String', btn3, ...
    'UserData', btn3, ...
    'Parent', handles.dialog );

if ~numel ( btn3 ), set ( handles.btn3, 'Visible', 'off' ); end


% Gets the original position of the uicontrols.
windowpos = get ( 0, 'ScreenSize' );
dialogpos = get ( handles.dialog, 'Position' );

% Gets the recomended size of the text.
[ text, textpos ] = textwrap ( handles.text, { text }, numel ( text ) + 1 );
set ( handles.text, 'String', text );

% Gets the recomended size for each button.
[ btn1, btn1pos ] = textwrap ( handles.btn1, { btn1 }, numel ( btn1 ) + 1 );
set ( handles.btn1, 'String', btn1 );
[ btn2, btn2pos ] = textwrap ( handles.btn2, { btn2 }, numel ( btn2 ) + 1 );
set ( handles.btn2, 'String', btn2 );
[ btn3, btn3pos ] = textwrap ( handles.btn3, { btn3 }, numel ( btn3 ) + 1 );
set ( handles.btn3, 'String', btn3 );

% Gets the optimal button size.
btnwidth    = max ( [ 54 btn1pos(3) btn2pos(3) btn3pos(3) ] );
btnheight   = max ( [ 28 btn1pos(4) btn2pos(4) btn3pos(4) ] );

btn1pos (3) = btnwidth;
btn2pos (3) = btnwidth;
btn3pos (3) = btnwidth;
btn1pos (4) = btnheight;
btn2pos (4) = btnheight;
btn3pos (4) = btnheight;

% Gets the total width of the button pack.
btnpack = btnwidth;
if strcmp ( get ( handles.btn2, 'Visible' ), 'on' ), btnpack = btnpack + 5 + btnwidth; end
if strcmp ( get ( handles.btn1, 'Visible' ), 'on' ), btnpack = btnpack + 5 + btnwidth; end

% Modifies the position of the uicontrols to fit the size of the text.
textpos (3) = max ( btnpack, textpos (3) );
textpos (2) = btn1pos (4) + 10;
set ( handles.text, 'Position', textpos );

dialogpos (3) = textpos (3) + 10;
dialogpos (4) = textpos (4) + btn1pos (4) + 14;
dialogpos (1) = ( windowpos (3) - dialogpos (3) ) / 2;
dialogpos (2) = ( windowpos (4) - dialogpos (4) ) / 2;
set ( handles.dialog, 'Position', dialogpos );

btn1pos (1) = dialogpos (3) - btn3pos (3) - 5 - btn2pos (3) - 5 - btn1pos (3) - 5;
set ( handles.btn1, 'Position', btn1pos );

btn2pos (1) = dialogpos (3) - btn3pos (3) - 5 - btn2pos (3) - 5;
set ( handles.btn2, 'Position', btn2pos );

btn3pos (1) = dialogpos (3) - btn3pos (3) - 5;
set ( handles.btn3, 'Position', btn3pos );

% Sets the callbacks.
set ( handles.btn1,   'Callback',        { @button_callback } )
set ( handles.btn2,   'Callback',        { @button_callback } )
set ( handles.btn3,   'Callback',        { @button_callback } )
set ( handles.btn1,   'KeyPressFcn',     { @button_keypress } )
set ( handles.btn2,   'KeyPressFcn',     { @button_keypress } )
set ( handles.btn3,   'KeyPressFcn',     { @button_keypress } )
set ( handles.dialog, 'CloseRequestFcn', { @cancelpress } )

guidata ( handles.dialog, handles );

% Shows the dialog.
set ( handles.dialog, 'Visible', 'on' );
guidata ( handles.dialog, handles );


% Sets the active field and pauses execution.
uicontrol ( handles.( default ) )
uiwait ( handles.dialog )

% Loads the stored data.
handles = guidata ( handles.dialog );

% Outputs the string and exits.
output = handles.output;
delete ( handles.dialog );


function button_callback ( hObject, varargin )

% Gets the handles data.
handles = guidata ( hObject );

% Sets the value for the output and saves it.
handles.output = get ( hObject, 'UserData' );
guidata ( hObject, handles );

% Continues with the execution.
uiresume ( handles.dialog )


function button_keypress ( hObject, eventdata )

% Gets the handles data.
handles = guidata ( hObject );

% Checks the pressed key.
switch lower ( eventdata.Key )
    
    % If the key is Return, saves.
    case 'return'
        button_callback ( hObject )
        
    % If the key is Escape, exits.
    case 'escape'
        uiresume ( handles.dialog )
end


function cancelpress ( hObject, varargin )

% Gets the handles data.
handles = guidata ( hObject );

% Continues with the execution.
uiresume ( handles.dialog )

