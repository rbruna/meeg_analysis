function varargout = s6_realignMRI(varargin)
% S6_REALIGNMRI MATLAB code for s6_realignMRI.fig
%      S6_REALIGNMRI, by itself, creates a new S6_REALIGNMRI or raises the existing
%      singleton*.
%
%      H = S6_REALIGNMRI returns the handle to a new S6_REALIGNMRI or the handle to
%      the existing singleton*.
%
%      S6_REALIGNMRI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in S6_REALIGNMRI.M with the given input arguments.
%
%      S6_REALIGNMRI('Property','Value',...) creates a new S6_REALIGNMRI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before s6_realignMRI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to s6_realignMRI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help s6_realignMRI

% Last Modified by GUIDE v2.5 22-Aug-2017 20:14:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @s6_realignMRI_OpeningFcn, ...
                   'gui_OutputFcn',  @s6_realignMRI_OutputFcn, ...
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
%#ok<*INUSL,*INUSD,*DEFNU,*ST2NM,*NASGU,*ASGLU>


function s6_realignMRI_OpeningFcn ( hObject, eventdata, handles, varargin )

% Defines the location of the files.
config.path.trans = '../../data/sources/transformation/';
config.path.mri   = '../../data/headmodel/';
config.path.patt  = '*.mat';


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Sets the original camera position.
campos ( handles.axes, [ -1172.4, 2046.9, 0019.9 ] )
set    ( handles.axes, 'NextPlot', 'add' )

% Gets the list of data files.
files            = dir ( sprintf ( '%s%s', config.path.trans, config.path.patt ) );
config.files     = { files.name };

if numel ( files ) < 1
    fprintf ( 1, 'No transformation files in the selected folder (%s).\n', config.path.trans );
    delete ( handles.realignMRI )
    return
end

% Initializes the subject.
config.current   = 2;


% Stores the configuration.
handles.config   = config;

% Loads the first subject.
loadSubject ( handles )


function loadTrans_Callback   ( hObject, eventdata, handles ), selectTrans  ( handles )
function loadMRI_Callback     ( hObject, eventdata, handles ), selectMRI    ( handles )

function defMRIfids_Callback  ( hObject, eventdata, handles ), setFiducial  ( handles )
function flipMRIfids_Callback ( hObject, eventdata, handles ), flipFiducial ( handles )
function fitMRIfids_Callback  ( hObject, eventdata, handles ), fitFiducial  ( handles )
function fitMRIICP_Callback   ( hObject, eventdata, handles ), fitUsingICP  ( handles )

function rxSlider_Callback    ( hObject, eventdata, handles ), moveRealign  ( handles )
function rySlider_Callback    ( hObject, eventdata, handles ), moveRealign  ( handles )
function rzSlider_Callback    ( hObject, eventdata, handles ), moveRealign  ( handles )

function xSlider_Callback     ( hObject, eventdata, handles ), moveRealign  ( handles )
function ySlider_Callback     ( hObject, eventdata, handles ), moveRealign  ( handles )
function zSlider_Callback     ( hObject, eventdata, handles ), moveRealign  ( handles )

function drawSensors_Callback ( hObject, eventdata, handles ), drawRealign  ( handles )
function projSensors_Callback ( hObject, eventdata, handles ), drawRealign  ( handles )
function showError_Callback   ( hObject, eventdata, handles ), drawRealign  ( handles )

function prevSubject_Callback ( hObject, eventdata, handles ), prevSubject  ( handles )
function nextSubject_Callback ( hObject, eventdata, handles ), nextSubject  ( handles )
function saveSubject_Callback ( hObject, eventdata, handles ), saveRealign  ( handles )


function nextSubject ( handles )

% Gets the current subject.
current = handles.config.current;

% If current subjects is the last one, exists.
if current == numel ( handles.config.files ), return; end

% Otherwise sets the current subject.
handles.config.current = current + 1;

% Loads the subject.
loadSubject ( handles )


function prevSubject ( handles )

% Gets the current subject.
current = handles.config.current;

% If current subjects is the first one, exists.
if current == 1, return; end

% Otherwise sets the current subject.
handles.config.current = current - 1;

% Loads the subject.
loadSubject ( handles )


function loadSubject ( handles )

% Disables the navigations buttons.
set ( handles.prevSubject, 'Enable', 'off' )
set ( handles.nextSubject, 'Enable', 'off' )
set ( handles.showError,   'Enable', 'off' )
set ( handles.fitMRIICP,   'Enable', 'off' )

% Deletes the axes.
cla  ( handles.axes )
axis ( handles.axes, 'off' )
drawnow


% Gets the file name.
transfile = sprintf ( '%s%s', handles.config.path.trans,  handles.config.files { handles.config.current } );

% Loads and initializes the data.
transdata = load ( transfile );

% Sanitizes the head shape definition, if required.
if isfield ( transdata.headshape, 'pnt' )
    transdata.headshape.pos = transdata.headshape.pnt;
    transdata.headshape     = rmfield ( transdata.headshape, 'pnt' );
    save ( '-v6', transfile, '-struct', 'transdata' );
    warndlg ( 'Head shape definition updated.', 'Warning', 'Modal' );
    uiwait ( findall ( 0, 'Name', 'Warning' ) )
end
if isfield ( transdata.headshape.fid, 'pnt' )
    transdata.headshape.fid.pos = transdata.headshape.fid.pnt;
    transdata.headshape.fid     = rmfield ( transdata.headshape.fid, 'pnt' );
    save ( '-v6', transfile, '-struct', 'transdata' );
    warndlg ( 'Head shape fiducials updated.', 'Warning', 'Modal' );
    uiwait ( findall ( 0, 'Name', 'Warning' ) )
end


handles.data = [];
handles.data.subject = transdata.subject;

% Stores the heads hape and the sensor definition.
handles.data.grad    = ft_convert_units ( transdata.grad,      'mm' );
handles.data.elec    = ft_convert_units ( transdata.elec,      'mm' );
handles.data.hshape  = ft_convert_units ( transdata.headshape, 'mm' );


% Puts the subject name in the GUI title bar.
set ( handles.realignMRI, 'Name', sprintf ( 'Subject ''%s''', transdata.subject ) );

% Initializes the MRI information.
handles.data.mriinfo.mrifile = '';

% Saves the data in the GUI.
guidata ( handles.realignMRI, handles );

% If any, tries to load the transformation.
if isfield ( transdata, 'mriinfo' )
    
    handles.data.mriinfo = transdata.mriinfo;
    
% Otherwise tries to load the subject's MRI.
else
    
    % Search for the subjects MRI in the MRI path.
    mrifiles = dir ( sprintf ( '%s%s*', handles.config.path.mri, transdata.subject ) );
    
    % If any, selects the first MRI file.
    if numel ( mrifiles )
        
        % Sets the MRI file name.
        handles.data.mriinfo.mrifile = sprintf ( '%s%s', handles.config.path.mri, mrifiles (1).name );
        
    % Otherwise ask the user for the MRI file to use.
    else
        selectMRI ( handles )
        
        % Recovers the information.
        handles = guidata ( handles.realignMRI );
    end
end

% Loads the MRI file.
getMRI ( handles );


% Recovers the information.
handles = guidata ( handles.realignMRI );

% Uses the stored transformation, if any.
if isfield ( handles.data.mriinfo, 'transform' )
    
    % If no units, assumes milimetes.
    if ~isfield ( handles.data.mriinfo, 'unit' )
        handles.data.mriinfo.unit = 'mm';
    end

    % Updates the transformation and resets the sliders.
    setTrans ( handles, handles.data.mriinfo );
    
% Otherwise fits the MEG fiducials to the MRI fiducials.
else
    
    % Performs the first transformation.
    fitFiducial ( handles )
end

% Recovers the information.
handles = guidata ( handles.realignMRI );

% Draws the figure.save
drawRealign ( handles )


% Enables the navigation buttons.
if handles.config.current > 1
    set ( handles.prevSubject, 'Enable', 'on'  );
end

if handles.config.current < numel ( handles.config.files )
    set ( handles.nextSubject, 'Enable', 'on'  );
end
if ~isempty ( handles.data.hshape.pos )
    set ( handles.showError, 'Enable', 'on'  )
    set ( handles.fitMRIICP, 'Enable', 'on'  )
end



function selectMRI ( handles )

% Asks for a file from the same subject.
[ filename, pathname ] = uigetfile ( sprintf ( '%s%s*.mat', handles.config.path.mri, handles.data.subject ) );

% If no selected file, returns.
if ~filename
    return
end

% Checks that the file contains the needed fields.
fileinfo = whos ( '-file', sprintf ( '%s%s', pathname, filename ) );
if all ( ismember ( { 'mri', 'scalp' }, { fileinfo.name } ) )
    
    % Sets the MRI file name.
    handles.data.mriinfo.mrifile = sprintf ( '%s%s', pathname, filename );
    
% Otherwise rises an error.
else
    errordlg ( 'The selected file does not contain a valid MRI file.', 'Error' )
    return
end

% Loads the MRI.
getMRI ( handles )

% Recovers the information.
handles = guidata ( handles.realignMRI );

% Fits the MEG fiducials to the MRI fiducials.
fitFiducial ( handles );


function getMRI ( handles )

% If no defined MRI, returns.
if ~isfield ( handles.data.mriinfo, 'mrifile' ) || isempty ( handles.data.mriinfo.mrifile )
    return
end

% If the file is not found, launches a message and returns.
if ~exist ( handles.data.mriinfo.mrifile, 'file' )
    errordlg ( 'The previously selected file cannot be found.', 'Error', 'Modal' );
    uiwait ( findall ( 0, 'Name', 'Error' ) )
    return
end

% Gets the current MRI information.
mriinfo              = handles.data.mriinfo;

% Gets the the scalp surface and the MRI fiducials, if defined.
mridata              = load ( mriinfo.mrifile, 'subject', 'landmark', 'transform', 'scalp' );

% Updates the MRI information with the MRI, units, if required.
if ~isfield ( mriinfo, 'unit' )
    mriinfo.unit         = mridata.transform.unit;
end

% Sanitizes the scalp definition, if required.
if isfield ( mridata.scalp, 'pnt' )
    mridata.scalp.pos = mridata.scalp.pnt;
    mridata.scalp     = rmfield ( tmridata.scalp, 'pnt' );
end

% Stores the updated MRI information in the figure data.
handles.data         = rmfield ( handles.data, intersect ( fieldnames ( handles.data ), { 'landmark' 'scalp' } ) );
handles.data.scalp   = ft_convert_units ( mridata.scalp, 'mm' );
handles.data.mriinfo = mriinfo;

% Stores the Neuromag fiducials in millimeters.
if isfield ( mridata, 'landmark' ) && isstruct ( mridata.landmark )
    handles.data.landmark = ft_transform_geometry ( mridata.transform.vox2nat, mridata.landmark.nm );
end

% Saves the data in the GUI.
guidata ( handles.realignMRI, handles );


function setFiducial ( handles )

% If no defined MRI, returns.
if ~isfield ( handles.data.mriinfo, 'mrifile' ) || isempty ( handles.data.mriinfo.mrifile )
    return
end

% Loads the MRI.
mridata         = load ( handles.data.mriinfo.mrifile, 'mri', 'landmark' );

% Creates a dummy MRI with only the anatomical data.
dummy           = [];
dummy.dim       = mridata.mri.dim;
dummy.anatomy   = mridata.mri.anatomy;
dummy.coordsys  = mridata.mri.coordsys;
dummy.transform = mridata.mri.transform;
dummy.unit      = mridata.mri.unit;

% Asks the user for the fiducials.
cfg             = [];
cfg.coordsys    = 'neuromag';
fiducial        = ft_volumerealign ( cfg, dummy );

% Checks that the fiducials are defined.
if any ( isnan ( fiducial.cfg.fiducial.lpa ) ) || any ( isnan ( fiducial.cfg.fiducial.nas ) ) || any ( isnan ( fiducial.cfg.fiducial.rpa ) ) 
    return
end

% Stores the fiducials in millimiters in the GUI data.
handles.data.landmark = ft_transform_geometry ( mridata.mri.transform, fiducial.cfg.fiducial );

% Asks if the fiducials should be saved in the MRI file.
answer          = mydlg_questdlg ( 'Store these fiducials in the MRI file?', 'Question', 'Yes', 'No', 'Yes' );

if strcmp ( answer, 'Yes' )
    landmark         = mridata.landmark;
    landmark.nm      = fiducial.cfg.fiducial;
    save ( '-v6', '-append', handles.data.mriinfo.mrifile, 'landmark' );
end

% Performs the first transformation.
fitFiducial ( handles );


function flipFiducial ( handles )

% If no defined MRI, returns.
if ~isfield ( handles.data.mriinfo, 'mrifile' ) || isempty ( handles.data.mriinfo.mrifile )
    return
end

% Loads the MRI.
mridata          = load ( handles.data.mriinfo.mrifile, 'mri', 'landmark' );

% Flips the LPA and RPA fiducials.
landmark         = handles.data.landmark;
landmark.lpa     = handles.data.landmark.rpa;
landmark.rpa     = handles.data.landmark.lpa;

% Stores the fiducials in the GUI data.
handles.data.landmark = landmark;

% Asks if the fiducials should be saved in the MRI file.
answer           = mydlg_questdlg ( 'Store these fiducials in the MRI file?', 'Question', 'Yes', 'No', 'Yes' );

if strcmp ( answer, 'Yes' )
    landmark         = mridata.landmark;
    landmark.nm      = ft_transform_geometry ( inv ( mridata.mri.transform ), handles.data.landmark );
    save ( '-v6', '-append', handles.data.mriinfo.mrifile, 'landmark' );
end

% Performs the first transformation.
fitFiducial ( handles );


function fitFiducial ( handles )

% If no fiducials in the MRI file, asks the user.
if ~isfield ( handles.data, 'landmark' )
    setFiducial ( handles );
    
    % Recovers the information.
    handles = guidata ( handles.realignMRI );
end

% If no fiduals, exits.
if ~isfield ( handles.data, 'landmark' ), return, end

% Gets the MRI fiducial positions.
mrifid = handles.data.landmark;
mrifid = [ mrifid.lpa; mrifid.nas; mrifid.rpa ];

% Gets the head shape fiducials.
hsfid  = handles.data.hshape.fid;
hslpa  = find ( strcmpi ( hsfid.label, 'LPA' ),    1 );
hsnas  = find ( strcmpi ( hsfid.label, 'Nasion' ), 1 );
hsrpa  = find ( strcmpi ( hsfid.label, 'RPA' ),    1 );
hsfid  = hsfid.pos ( [ hslpa hsnas hsrpa ], : );

mrifid ( isnan ( mrifid ) ) = 0;

% Updates the transformation and resets the sliders.
setTrans ( handles, my_rigid_transform ( hsfid', mrifid' ) );


function fitUsingICP ( handles )

% Gets the scalp and the head shape.
hshape    = handles.data.hshape;
scalp     = handles.data.scalp;

% Gets the complete transformation.
transform = handles.data.transform.original * handles.data.transform.user;
scalp     = ft_transform_geometry ( transform, scalp );

% Calculates the transformation from head shape to MRI scalp.
invtrans  = my_icp ( scalp.bnd.pos, hshape.pos );

% Updates the transformation and resets the sliders.
setTrans ( handles, transform / invtrans );


function selectTrans ( handles )

% Asks for a file from the same subject.
[ filename, pathname ] = uigetfile ( sprintf ( '%s%s*.mat', handles.config.path.trans, handles.data.subject ) );

% Checks that the file contains the needed fields.
fileinfo = whos ( '-file', sprintf ( '%s%s', pathname, filename ) );
if all ( ismember ( { 'mriinfo' }, { fileinfo.name } ) )
    
    % Gets the file name.
    taskfile  = sprintf ( '%s%s', pathname,  filename );
    
    % Loads the data.
    taskdata  = load ( taskfile, 'mriinfo' );
    
    % Updates the transformation and resets the sliders.
    setTrans ( handles, taskdata.mriinfo );
    
% Otherwise rises an error.
else
    errordlg ( 'The selected file does not contain a valid transformation.', 'Error' )
end


function setTrans ( handles, transform )

% Extracts the transformation matrix, if required.
if isstruct ( transform )

    % Gets the transformation matrix.
    transinfo = transform;
    transform = transinfo.transform;

    % Converts the transformation matrix into milimeters.
    scale     = ft_scalingfactor ( transinfo.unit, 'mm' );
    transform ( 1: 3, 4 ) = scale * transform ( 1: 3, 4 );
end

% Sets the transformation.
handles.data.transform.original = transform;
handles.data.transform.user     = eye (4);

% Resets the sliders.
set ( handles.xSlider,  'Value', .5 );
set ( handles.ySlider,  'Value', .5 );
set ( handles.zSlider,  'Value', .5 );

set ( handles.rxSlider, 'Value', .5 );
set ( handles.rySlider, 'Value', .5 );
set ( handles.rzSlider, 'Value', .5 );

% Saves the data in the GUI.
guidata ( handles.realignMRI, handles );

% Draws the figure.
drawRealign ( handles )



function moveRealign ( handles )

% If no transformation, exits.
if ~isfield ( handles.data, 'transform' ), return, end


% Gets the defined shift and rotation.
shiftX = ( get ( handles.xSlider,  'Value' ) - .5 ) * 100;
shiftY = ( get ( handles.ySlider,  'Value' ) - .5 ) * 100;
shiftZ = ( get ( handles.zSlider,  'Value' ) - .5 ) * 100;

angle1 = ( get ( handles.rxSlider, 'Value' ) - .5 );
angle2 = ( get ( handles.rySlider, 'Value' ) - .5 );
angle3 = ( get ( handles.rzSlider, 'Value' ) - .5 );

% Sets the shift.
shift   = eye (4);
shift   ( [ 13 14 15 16 ] ) = [ shiftX shiftY shiftZ 1 ];

% Sets the rotations.
rotate1 = eye (4);
rotate1 ( [  6  7 11 10 ] ) = [ cos( angle1 ) sin( angle1 ) cos( angle1 ) -sin( angle1 ) ];

rotate2 = eye (4);
rotate2 ( [  1  9 11  3 ] ) = [ cos( angle2 ) sin( angle2 ) cos( angle2 ) -sin( angle2 ) ];

rotate3 = eye (4);
rotate3 ( [  1  2  6  5 ] ) = [ cos( angle3 ) sin( angle3 ) cos( angle3 ) -sin( angle3 ) ];

% Stores the user transformation matrix in the GUI data.
handles.data.transform.user = shift * rotate1 * rotate2 * rotate3;

% Saves the data in the GUI.
guidata ( handles.realignMRI, handles );

% Draws the figure.
drawRealign ( handles )


function drawRealign ( handles )

% Gets the previous camera position.
camera    = campos ( handles.axes );

% Cleans the active axes and the info text box.
cla   ( handles.axes );
set   ( handles.infoText, 'String', '' )


% Gets the head shape, the MEG fiducials and the sensors position.
hpiindex  = strncmp ( handles.data.hshape.label, 'hpi_', 4 );
hpicoils  = handles.data.hshape.pos (  hpiindex, : );
hshape    = handles.data.hshape.pos ( ~hpiindex, : );
hsfid     = handles.data.hshape.fid.pos;

% Draws the head shape and the MEG fiducials.
plot3 ( handles.axes, hshape   ( :, 1 ), hshape   ( :, 2 ), hshape   ( :, 3 ), '.b' )
plot3 ( handles.axes, hsfid    ( :, 1 ), hsfid    ( :, 2 ), hsfid    ( :, 3 ), '.k', 'MarkerSize', 20 )
plot3 ( handles.axes, hpicoils ( :, 1 ), hpicoils ( :, 2 ), hpicoils ( :, 3 ), '.r', 'MarkerSize', 20 )

% If required, draws the sensors.
if get ( handles.drawSensors, 'Value' ) && isfield ( handles.data.grad, 'chanpos' )
    sensors   = handles.data.grad.chanpos;
    plot3 ( handles.axes, sensors ( :, 1 ), sensors ( :, 2 ), sensors ( :, 3 ), '.r' )
end

% Fixes the camera target and sets the camera to 'orbit' mode.
axis  ( handles.axes, 'equal', 'vis3d', 'off' );
set   ( handles.axes, 'CameraUpVector', [ 0 0 1 ], 'CameraViewAngle', 8, 'CameraTarget', [  0  0 40 ] )
cameratoolbar ( handles.realignMRI, 'SetMode', 'Orbit' )

% Restores the camera position.
campos ( handles.axes, camera );


% If no transformation, exits.
if ~isfield ( handles.data, 'transform' ), return, end

% Gets the complete transformation.
transform = handles.data.transform.original * handles.data.transform.user;

% Applies the transformation to the scalp.
scalp     = ft_transform_geometry ( transform, handles.data.scalp );

% Fixes the scalp, if required.
if isfield ( scalp.bnd, 'pnt' )
    scalp.bnd.pos = scalp.bnd.pnt;
end


% If required, draws the sensors.
if get ( handles.drawSensors, 'Value' ) && isfield ( handles.data, 'elec' ) && isfield ( handles.data.elec, 'chanpos' )
    
    % Gets the sensor positions.
    sensors   = handles.data.elec.chanpos;
    sensors   = sensors ( all ( isfinite ( sensors ), 2 ), : );
    
    % Traslades the electrodes to the surface of the scalp, if required.
    if get ( handles.projSensors, 'Value' )
        for eindex = 1: size ( sensors, 1 )
            [ ~, Pm ] = NFT_dmp ( sensors ( eindex, : ), scalp.bnd.pos, scalp.bnd.tri );
            sensors ( eindex, : ) = Pm;
        end
    end
    
    % Draws the sensors.
    plot3 ( handles.axes, sensors ( :, 1 ), sensors ( :, 2 ), sensors ( :, 3 ), '.r' )
end


% Draws and lightens the scalp.
ft_plot_mesh ( scalp.bnd, 'facecolor', 'skin', 'edgecolor', 'none' );
view ( [   90,   0 ] ), camlight
view ( [ -150,   0 ] ), camlight
lighting gouraud
alpha 0.5

% Restores the camera position.
campos ( handles.axes, camera );


% If required, shows the errors.
if get ( handles.showError,   'Value' )
    
    % Extracts the head shape and scalp points.
    hshape = handles.data.hshape;
    hsp    = hshape.pos;
    scalp  = ft_transform_geometry ( transform, handles.data.scalp.bnd );
    sp     = scalp.pos;
    
    % Calculates the minimum distance from a head shape point to a scalp point.
    dists  = zeros ( size ( hsp, 1 ), 1 );
    for i = 1: numel ( dists )
        dist        = hsp ( i * ones ( size ( sp, 1 ), 1 ), : ) - sp;
        [ ~, pnt ]  = min ( sum ( dist .^ 2, 2 ) );
        dists ( i ) = sqrt ( sum ( ( hsp ( i, : ) - sp ( pnt, : ) ) .^ 2 ) );
    end
    
    % Sets the error information.
    info {1} = sprintf ( 'Maximum error: %.1f mm. Mean error: %.1f (%.1f) mm. Median error: %.1f mm.', max ( dists ), mean ( dists ), std ( dists ), median ( dists ) );
    info {2} = sprintf ( 'Number of head shape points farther than 5mm form scalp: %i (%.1f%%).', sum ( dists > 5 ), 100 * sum ( dists > 5 ) / numel ( dists ) );
    
    % Displays the error information in the info text box.
    set ( handles.infoText, 'String', info )
end


function saveRealign ( handles )

% Disables the buttons.
set ( handles.saveSubject, 'Enable', 'off' )
set ( handles.prevSubject, 'Enable', 'off' )
set ( handles.nextSubject, 'Enable', 'off' )
drawnow

% Gets the output data.
transinfo = [];
transinfo.mriinfo = handles.data.mriinfo;

% Gets the total transformation.
transform = handles.data.transform.original * handles.data.transform.user;

% Transforms the transformation matrix into the original units.
scale     = ft_scalingfactor ( 'mm', transinfo.mriinfo.unit );
transform ( 1: 3, 4 ) = scale * transform ( 1: 3, 4 );

% Makes the transformation changes permanent.
transinfo.mriinfo.transform = transform;

% Saves the current subject in the output folder.
save ( '-v6', '-append', sprintf ( '%s%s', handles.config.path.trans, handles.config.files { handles.config.current } ), '-struct', 'transinfo' )

% Updates the transformation and resets the sliders.
setTrans ( handles, transinfo.mriinfo )

% Enables the buttons.
set ( handles.saveSubject, 'Enable', 'on' )
if handles.config.current > 1
    set ( handles.prevSubject, 'Enable', 'on' )
end
if handles.config.current < numel ( handles.config.files )
    set ( handles.nextSubject, 'Enable', 'on' )
end


function s6_realignMRI_OutputFcn ( hObject, eventdata, handles )
