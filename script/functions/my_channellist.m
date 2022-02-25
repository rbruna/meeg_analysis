function select = my_channellist ( label, select, wintitle )

% Based on FieldTrip 20160222 functions:
% * select_channel_list by Robert Oostenveld

if nargin < 3
    wintitle = 'Select the desired channels';
end

% Creates the variables.
userdata        = [];
userdata.label  = label;
userdata.select = false ( size ( label ) );
userdata.moved  = false ( size ( label ) );

% Sets the selection.
userdata.select ( select ) = true;
userdata.moved  ( select ) = true;


pos      = get ( 0, 'DefaultFigurePosition' );
pos ( 3: 4 ) = [ 290 300 ];


% Creates the dialog box in the default position.
h      = dialog ( 'Name', wintitle, 'Position', pos, 'HandleVisibility', 'callback' );

% Creates the elements.
handles = [];
handles.text1 = uicontrol ( h, 'style', 'text',       'position', [ 10 240+20 80  20], 'string', 'unselected' );
handles.text2 = uicontrol ( h, 'style', 'text',       'position', [200 240+20 80  20], 'string', 'selected' );
handles.list1 = uicontrol ( h, 'style', 'listbox',    'position', [ 10  40+20 80 200], 'min', 0, 'max', 2, 'tag', 'lbunsel' );
handles.list2 = uicontrol ( h, 'style', 'listbox',    'position', [200  40+20 80 200], 'min', 0, 'max', 2, 'tag', 'lbsel' );
handles.butt1 = uicontrol ( h, 'style', 'pushbutton', 'position', [105 175+20 80  20], 'string', 'add all >'   , 'callback', @label_addall );
handles.butt2 = uicontrol ( h, 'style', 'pushbutton', 'position', [105 145+20 80  20], 'string', 'add >'       , 'callback', @label_add );
handles.butt3 = uicontrol ( h, 'style', 'pushbutton', 'position', [105 115+20 80  20], 'string', '< remove'    , 'callback', @label_rem );
handles.butt4 = uicontrol ( h, 'style', 'pushbutton', 'position', [105  85+20 80  20], 'string', '< remove all', 'callback', @label_remall );
handles.butt5 = uicontrol ( h, 'style', 'pushbutton', 'position', [ 55  10    80  20], 'string', 'Cancel',       'callback', 'close' );
handles.butt6 = uicontrol ( h, 'style', 'pushbutton', 'position', [155  10    80  20], 'string', 'OK',           'callback', 'uiresume' );
drawnow

% Fills the dialog.
setappdata ( h, 'userdata', userdata );
setappdata ( h, 'handles',  handles  );
label_redraw ( h )
uiwait ( h )

% Checks if the figure still exists (OK pressed).
if ishandle ( h )
    userdata = getappdata ( h, 'userdata' );
    select = find ( userdata.select );
    delete ( h )
end
end

function label_redraw ( h )
userdata = getappdata ( h, 'userdata' );
handles  = getappdata ( h, 'handles'  );

% Fills both lists.
set ( handles.list1, 'String', userdata.label ( ~userdata.select ) );
set ( handles.list2, 'String', userdata.label (  userdata.select ) );

% Determines the origin and destination lists.
if all ( userdata.select ( userdata.moved ) )
    orig = ~userdata.select;
    dest =  userdata.select;
else
    orig =  userdata.select;
    dest = ~userdata.select;
end

% Gets the index of the next element in the origin list.
next = find ( userdata.moved ( orig | userdata.moved ), 1, 'last' ) - sum ( userdata.moved ) + 1;
next = min ( next, sum ( orig ) );

% Gets the indexes of the moved elements in the destination list.
move = find ( userdata.moved ( dest ) );

% Selects the correct items.
if all ( userdata.select ( userdata.moved ) )
    set ( handles.list1, 'Value', next )
    set ( handles.list2, 'Value', move )
else
    set ( handles.list2, 'Value', next )
    set ( handles.list1, 'Value', move )
end

drawnow
delete ( findobj ( h, 'Type', 'axes' ) )

% Sows the dialog, if needed.
% set ( h, 'Visible', 'on' )
end

function label_addall ( h, eventdata, handles, varargin ) %#ok<INUSD>
h = ancestor ( h, 'figure' );
userdata = getappdata ( h, 'userdata' );

% If no items does nothing.
if ~any ( ~userdata.select ), return, end

userdata.select = true  ( size ( userdata.label ) );
userdata.moved  = true  ( size ( userdata.label ) );

% Fills the dialog.
setappdata ( h, 'userdata', userdata );
label_redraw ( h )
end

function label_remall ( h, eventdata, handles, varargin ) %#ok<INUSD>
h = ancestor ( h, 'figure' );
userdata = getappdata ( h, 'userdata' );

% If no items does nothing.
if ~any ( userdata.select ), return, end

userdata.select = false ( size ( userdata.label ) );
userdata.moved  = true  ( size ( userdata.label ) );

% Fills the dialog.
setappdata ( h, 'userdata', userdata );
label_redraw ( h )
end

function label_add ( h, eventdata, handles, varargin ) %#ok<INUSD>
h = ancestor ( h, 'figure' );
userdata = getappdata ( h, 'userdata' );
handles  = getappdata ( h, 'handles'  );

% If no items does nothing.
if ~any ( ~userdata.select ), return, end

% Gets the index of the unselected items.
items = find ( ~userdata.select );
item  = get ( handles.list1, 'Value' );

% Moves the item to the unselected list.
userdata.select ( items ( item ) ) = true;
userdata.moved  = false ( size ( userdata.label ) );
userdata.moved  ( items ( item ) ) = true;

% Fills the dialog.
setappdata ( h, 'userdata', userdata );
label_redraw ( h )
end

function label_rem ( h, eventdata, handles, varargin ) %#ok<INUSD>
h = ancestor ( h, 'figure' );
userdata = getappdata ( h, 'userdata' );
handles  = getappdata ( h, 'handles'  );

% If no items does nothing.
if ~any ( userdata.select ), return, end

% Gets the index of the selected items.
items = find ( userdata.select );
item  = get ( handles.list2, 'Value' );

% Moves the item to the unselected list.
userdata.select ( items ( item ) ) = false;
userdata.moved  = false ( size ( userdata.label ) );
userdata.moved  ( items ( item ) ) = true;

% Fills the dialog.
setappdata ( h, 'userdata', userdata );
label_redraw ( h )
end
