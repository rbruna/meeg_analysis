function varargout = selectEKGlead(varargin)
% SELECTEKGLEAD MATLAB code for selectEKGlead.fig
%      SELECTEKGLEAD, by itself, creates a new SELECTEKGLEAD or raises the existing
%      singleton*.
%
%      H = SELECTEKGLEAD returns the handle to a new SELECTEKGLEAD or the handle to
%      the existing singleton*.
%
%      SELECTEKGLEAD('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SELECTEKGLEAD.M with the given input arguments.
%
%      SELECTEKGLEAD('Property','Value',...) creates a new SELECTEKGLEAD or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before selectEKGlead_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to selectEKGlead_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help selectEKGlead

% Last Modified by GUIDE v2.5 20-Mar-2016 00:54:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @selectEKGlead_OpeningFcn, ...
                   'gui_OutputFcn',  @selectEKGlead_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% Deactivation of the unwanted warnings.
%#ok<*INUSL,*INUSD,*DEFNU,*ST2NM>


function selectEKGlead_OpeningFcn ( hObject, eventdata, handles, varargin )

% Choose default command line output for selectEKGlead
handles.output = false;

% Update handles structure
guidata ( hObject, handles )

% If no data returns.
if nargin == 3, return, end

% Gets the data.
handles.data.data  = varargin {1};
handles.data.label = varargin {2};

% Gets the beats as measured from each candidate.
handles.data.beats = zeros ( size ( handles.data.data ) );

for cindex = 1: numel ( handles.data.label )
    handles.data.beats ( cindex, :, : ) = prekalima ( squeeze ( handles.data.data ( cindex, :, : ) ) );
end

% Initializes the metada.
handles.meta.shift = 0;

% Plots the data.
drawCandidates ( handles )

% Updates the handles structure.
guidata ( hObject, handles )
uiwait



function select1_Callback ( hObject, eventdata, handles )

% Sets the output.
handles.output = handles.meta.shift + 1;
guidata ( hObject, handles )

% Exits.
uiresume

function select2_Callback ( hObject, eventdata, handles )

% Sets the output.
handles.output = handles.meta.shift + 2;
guidata ( hObject, handles )

% Exits.
uiresume

function select3_Callback ( hObject, eventdata, handles )

% Sets the output.
handles.output = handles.meta.shift + 3;
guidata ( hObject, handles )

% Exits.
uiresume


function prev_Callback    ( hObject, eventdata, handles )

% Increases the shift.
handles.meta.shift = handles.meta.shift - 1;

drawCandidates ( handles )


function next_Callback    ( hObject, eventdata, handles )

% Increases the shift.
handles.meta.shift = handles.meta.shift + 1;

drawCandidates ( handles )

function selectEKGlead_CloseRequestFcn ( hObject, eventdata, handles ), uiresume

function varargout = selectEKGlead_OutputFcn ( hObject, eventdata, handles )

% Sets the output.
varargout {1} = handles.output;

% Closes the window.
delete ( hObject )


function drawCandidates ( handles )

% Disables the navigation buttons.
set ( handles.prev, 'Enable', 'off' )
set ( handles.next, 'Enable', 'off' )

% Hides the axeses and the buttons.
set ( handles.axes1, 'Visible', 'off' )
set ( handles.axes2, 'Visible', 'off' )
set ( handles.axes3, 'Visible', 'off' )

set ( handles.select1, 'Visible', 'off' )
set ( handles.select2, 'Visible', 'off' )
set ( handles.select3, 'Visible', 'off' )

% Enumerates the axeses and the buttons.
axeses  = cat ( 1, handles.axes1, handles.axes2, handles.axes3 );
buttons = cat ( 1, handles.select1, handles.select2, handles.select3 );

% Writes the three candidates.
for cindex = 1: 3
    
    % If no more candidates ends the loop.
    if handles.meta.shift + cindex > numel ( handles.data.label )
        break
    end
    
    
    % Sets the title.
    set ( buttons ( cindex ), 'String', handles.data.label { handles.meta.shift + cindex } );
    
    % Clears the axes.
    cla ( axeses ( cindex ) );
    
    % Draws the components and the extracted beats.
    plot ( axeses ( cindex ), handles.data.data  ( handles.meta.shift + cindex, : ) )
    plot ( axeses ( cindex ), handles.data.beats ( handles.meta.shift + cindex, : ), 'r' )
    
    % Hides the ticks.
    set ( axeses ( cindex ), 'XTick', [] )
    set ( axeses ( cindex ), 'YTick', [] )
    
    % Enables horizontal zoom.
    zoom xon
    
    
    % Shows the axeses and the button.
    set ( axeses  ( cindex ), 'Visible', 'on' )
    set ( buttons ( cindex ), 'Visible', 'on' )
    
end

% Links all the axeses.
linkaxes ( axeses, 'x' )

% Enables the previous and next condidate buttons, if needed.
if handles.meta.shift > 0
    set ( handles.prev, 'Enable', 'on' )
end

if handles.meta.shift < numel ( handles.data.label ) - 3
    set ( handles.next, 'Enable', 'on' )
end

% Updates the handles structure.
guidata ( handles.selectEKGlead, handles )
