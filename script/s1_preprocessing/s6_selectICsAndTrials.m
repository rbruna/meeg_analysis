function varargout = s6_selectICsAndTrials ( varargin )
% S6_SELECTICSANDTRIALS MATLAB code for s6_selectICsAndTrials.fig
%      S6_SELECTICSANDTRIALS, by itself, creates a new S6_SELECTICSANDTRIALS or raises the existing
%      singleton*.
%
%      H = S6_SELECTICSANDTRIALS returns the handle to a new S6_SELECTICSANDTRIALS or the handle to
%      the existing singleton*.
%
%      S6_SELECTICSANDTRIALS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in S6_SELECTICSANDTRIALS.M with the given input arguments.
%
%      S6_SELECTICSANDTRIALS('Property','Value',...) creates a new S6_SELECTICSANDTRIALS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before s6_selectICsAndTrials_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to s6_selectICsAndTrials_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help s6_selectICsAndTrials

% Last Modified by GUIDE v2.5 14-May-2016 20:26:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @s6_selectICsAndTrials_OpeningFcn, ...
                   'gui_OutputFcn',  @s6_selectICsAndTrials_OutputFcn, ...
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


function s6_selectICsAndTrials_OpeningFcn ( hObject, eventdata, handles, varargin )

clc

% Sets the paths.
config.path.segs      = '../../data/sketch/';
config.path.patt      = '*.mat';

% Sets the configuration parameters.
config.timeband       = [  2 30 ];
config.freqband       = [  1 45 ];
config.viewband       = [  0 45 ];


% Sets the default background color.
elements  = findobj ( hObject, 'Type', 'uipanel', '-or', 'Style', 'text', '-or', 'Style', 'pushbutton', '-or', 'Style', 'togglebutton', '-or', 'Style', 'checkbox' );
set ( elements, 'BackgroundColor', get ( hObject,  'Color' ) )


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Fills the list of IC and trial types.
config.comptypes      = { 'Data IC', 'EOG IC', 'EKG IC', 'Noisy IC' };
config.trialtypes     = { 'Data trial', 'Noisy trial' };

set ( handles.popupICType,    'String', config.comptypes  );
set ( handles.popupTrialType, 'String', config.trialtypes );


% Gets the list of data files.
filenames = dir ( sprintf ( '%s%s', config.path.segs, config.path.patt ) );

handles.data.folder   = config.path.segs;
handles.data.filename = { filenames.name }';
handles.data.current  = 1;


% Stores the configuration.
handles.config        = config;
guidata ( handles.ICsViewer, handles );

% Shows the first subject file.
show ( handles )


function popupIC_Callback              ( hObject, eventdata, handles ), updateSingle ( handles )
function popupTrial_Callback           ( hObject, eventdata, handles ), updateSingle ( handles )

function toggleTrialsOriginal_Callback ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleICsOriginal_Callback    ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleKalima_Callback         ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleOriginal_Callback       ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleEOG_Callback            ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleEKG_Callback            ( hObject, eventdata, handles ), updateMulti ( handles )
function toggleEMG_Callback            ( hObject, eventdata, handles ), updateMulti ( handles )
function uitoggleTF_ClickedCallback    ( hObject, eventdata, handles ), updateMulti ( handles )

function uibuttonSave_ClickedCallback  ( hObject, eventdata, handles ), savedata ( handles )


function popupTrialType_Callback       ( hObject, eventdata, handles )

% Gets the selected trial and its new type.
trial     = get ( handles.popupTrial, 'Value' );
trialtype = get ( hObject, 'Value' );

% Stores the data type for the selected trial.
handles.current.trialtype ( trial ) = trialtype - 1;

% Updates the figures.
updateMulti ( handles )


function popupICType_Callback          ( hObject, eventdata, handles )

% Gets the selected IC and its new type.
IC        = get ( handles.popupIC,    'Value' );
ICtype    = get ( hObject, 'Value' );

% Stores the data type for the selected IC.
handles.current.comptype  ( IC    ) = ICtype - 1;

% Updates the figures.
updateMulti ( handles )


function buttonTrialsReset_Callback    ( hObject, eventdata, handles )

% Asks for confirmation.
if strcmp ( questdlg ( 'Are you sure?', 'Question', 'Yes', 'No', 'No' ), 'Yes' )

    % Sets all the trial types to 0.
    handles.current.trialtype (:) = 0;
    
    % Updates the figures.
    updateMulti ( handles )
end


function buttonICsReset_Callback       ( hObject, eventdata, handles )

% Asks for confirmation.
if strcmp ( questdlg ( 'Are you sure?', 'Question', 'Yes', 'No', 'No' ), 'Yes' )
    
    % Sets all the IC types to 0.
    handles.current.comptype  (:) = 0;
    
    % Updates the figures.
    updateMulti ( handles )
end


function toggleICsGlobal_Callback      ( hObject, eventdata, handles )
values   = get ( get ( handles.axesIC,      'Children' ), 'YData' );
if iscell ( values ), values = cell2mat ( values ); end
maxvalue = 1.1 * max ( abs ( values (:) ) ) + realmin ( 'single' );

% If temporal data the minimum is minus the maximum.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    minvalue = -maxvalue;
    
% If frequency data the minimum is 0.
else
    minvalue = 0;
end

if get ( hObject, 'Value' ), set ( handles.axesIC,    'YLim', get ( handles.axesTrials, 'YLim' ) )
else                         set ( handles.axesIC,    'YLim', [ minvalue maxvalue ] )
end


function toggleTrialsGlobal_Callback   ( hObject, eventdata, handles )
values   = get ( get ( handles.axesTrial,   'Children' ), 'YData' );
if iscell ( values ), values = cell2mat ( values ); end
maxvalue = 1.1 * max ( abs ( values (:) ) ) + realmin ( 'single' );

% If temporal data the minimum is minus the maximum.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    minvalue = -maxvalue;
    
% If frequency data the minimum is 0.
else
    minvalue = 0;
end

if get ( hObject, 'Value' ), set ( handles.axesTrial, 'YLim', get ( handles.axesTrials, 'YLim' ) )
else                         set ( handles.axesTrial, 'YLim', [ minvalue maxvalue ] )
end


function toggleMeanGlobal_Callback     ( hObject, eventdata, handles )
values   = get ( get ( handles.axesMean,    'Children' ), 'YData' );
if iscell ( values ), values = cell2mat ( values ); end
maxvalue = 1.1 * max ( abs ( values (:) ) ) + realmin ( 'single' );

% If temporal data the minimum is minus the maximum.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    minvalue = -maxvalue;
    
% If frequency data the minimum is 0.
else
    minvalue = 0;
end

if get ( hObject, 'Value' ), set ( handles.axesMean,  'YLim', get ( handles.axesTrials, 'YLim' ) )
else                         set ( handles.axesMean,  'YLim', [ minvalue maxvalue ] )
end


function toggleResGlobal_Callback      ( hObject, eventdata, handles )
values   = get ( get ( handles.axesRes, 'Children' ), 'YData' );
if iscell ( values ), values = cell2mat ( values ); end
maxvalue = 1.1 * max ( abs ( values (:) ) ) + realmin ( 'single' );

% If temporal data the minimum is minus the maximum.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    minvalue = -maxvalue;
    
% If frequency data the minimum is 0.
else
    minvalue = 0;
end

if get ( hObject, 'Value' ), set ( handles.axesRes,   'YLim', get ( handles.axesTrials, 'YLim' ) )
else                         set ( handles.axesRes,   'YLim', [ minvalue maxvalue ] )
end



function buttonPrev_Callback           ( hObject, eventdata, handles )
if handles.data.current > 1
    handles.data.current = handles.data.current - 1;
end

% Updates the data.
show ( handles )


function buttonNext_Callback           ( hObject, eventdata, handles )
if handles.data.current < numel ( handles.data.filename )
    handles.data.current = handles.data.current + 1;
end

% Updates the data.
show ( handles )



function show ( handles )

% Temporary disables the subject navigation buttons.
set ( handles.buttonPrev,   'Enable', 'off' )
set ( handles.buttonNext,   'Enable', 'off' )
set ( handles.uibuttonSave, 'Enable', 'off' )

% Disables the EOG, EKG and EMG buttons.
set ( handles.toggleEOG,    'Enable', 'off' )
set ( handles.toggleEKG,    'Enable', 'off' )
set ( handles.toggleEMG,    'Enable', 'off' )

% Disables the time/frequency toggle.
set ( handles.uitoggleTF,   'Enable', 'off' )
drawnow

% Gets the subject's data.
files     = numel ( handles.data.filename );
current   = handles.data.current;

% Loads data for the current subject.
filename  = handles.data.filename { current };
filename  = sprintf ( '%s%s', handles.data.folder, filename );

taskdata  = load ( filename );


% If no last time saved, initializes the date field.
if ~isfield ( taskdata, 'updated' ), taskdata.updated = 'No yet saved'; end

subject   = taskdata.subject;
task      = taskdata.task;
stage     = taskdata.stage;
channel   = taskdata.channel;
fileinfo  = taskdata.fileinfo;
trialinfo = taskdata.trialinfo;
compinfo  = taskdata.compinfo;
cleaninfo = taskdata.cleaninfo;
trialdata = taskdata.freqdata;
updated   = taskdata.updated;

% Gets the IC components info.
subject   = taskdata.subject;
compdata  = compinfo.SOBI;
mixing    = compdata.mixing;
topolabel = compdata.topolabel;


% Initializes the IC and trial types, if not existent.
if ~isfield ( cleaninfo,       'comp'  ), cleaninfo.trial = []; end
if ~isfield ( cleaninfo.comp,  'types' ), cleaninfo.comp. types = handles.config.comptypes;  end
if ~isfield ( cleaninfo.comp,  'type'  ), cleaninfo.comp. type  = zeros ( size ( topolabel ) ); end

if ~isfield ( cleaninfo,       'trial' ), cleaninfo.trial = []; end
if ~isfield ( cleaninfo.trial, 'types' ), cleaninfo.trial.types = handles.config.trialtypes; end
if ~isfield ( cleaninfo.trial, 'type'  ), cleaninfo.trial.type  = zeros ( size ( trialdata.trial ) );    end

% Lists the IC and trial types.
set ( handles.popupTrialType, 'String', cleaninfo.trial.types )
set ( handles.popupICType,    'String', cleaninfo.comp. types  )

% Generates a vector with the type of trials and ICs.
handles.current.trialtype = cleaninfo.trial.type;
handles.current.comptype  = cleaninfo.comp. type;


% Gets the MEG, EMG and EKG indexes.
MEGidx    = ft_channelselection ( topolabel, trialdata.label );
MEGidx    = ismember ( trialdata.label, MEGidx );
EOGidx    = ft_channelselection ( 'EOG', trialdata.label );
EOGidx    = ismember ( trialdata.label, EOGidx );
EOGidx    = find ( EOGidx, 1, 'first' );
EKGidx    = ft_channelselection ( 'ECG', trialdata.label );
EKGidx    = ismember ( trialdata.label, EKGidx );
EKGidx    = find ( EKGidx, 1, 'first' );
EMGidx    = ft_channelselection ( 'EMG', trialdata.label );
EMGidx    = ismember ( trialdata.label, EMGidx );
EMGidx    = find ( EMGidx, 1, 'first' );


% Extracts both the ERF and the spectrum from the data.
data      = cat ( 3, taskdata.erfdata.trial {:} );
time      = taskdata.erfdata.time {1};

MEGtdata  = data     ( MEGidx, :, : );
EOGtdata  = data     ( EOGidx, :, : );
EKGtdata  = data     ( EKGidx, :, : );
EMGtdata  = data     ( EMGidx, :, : );

data      = permute ( taskdata.freqdata.fourierspctrm, [ 2 3 1 ] );
freq      = taskdata.freqdata.freq;

MEGfdata  = data     ( MEGidx, :, : );
EOGfdata  = data     ( EOGidx, :, : );
EKGfdata  = data     ( EKGidx, :, : );
EMGfdata  = data     ( EMGidx, :, : );

% Demeans the temporal data.
MEGtdata  = bsxfun ( @minus, MEGtdata, mean ( MEGtdata, 2 ) );
EOGtdata  = bsxfun ( @minus, EOGtdata, mean ( EOGtdata, 2 ) );
EKGtdata  = bsxfun ( @minus, EKGtdata, mean ( EKGtdata, 2 ) );
EMGtdata  = bsxfun ( @minus, EMGtdata, mean ( EMGtdata, 2 ) );

% Extracts the metadata.
trials    = numel ( taskdata.erfdata.trial );
channels  = sum  ( MEGidx );


% Stores the data and metadata in the handles structure.
handles.current.data.tMEG   = MEGtdata;
handles.current.data.tEOG   = EOGtdata;
handles.current.data.tEKG   = EKGtdata;
handles.current.data.tEMG   = EMGtdata;
handles.current.times       = time;

handles.current.data.fMEG   = MEGfdata;
handles.current.data.fEOG   = EOGfdata;
handles.current.data.fEKG   = EKGfdata;
handles.current.data.fEMG   = EMGfdata;
handles.current.freqs       = freq;

% handles.current.samples     = samples;
handles.current.topolabel   = topolabel;
handles.current.mixing      = mixing;
handles.current.subject     = subject;
handles.current.task        = task;
handles.current.stage       = stage;
handles.current.channel     = channel;
handles.current.updated     = updated;

% Sets the labels for trials and ICs.
labels.trials = cellfun ( @( number ) sprintf ( 'Trial %i', number ), num2cell ( 1: trials ),   'UniformOutput', false )';
labels.ICs    = cellfun ( @( number ) sprintf ( 'IC %i',    number ), num2cell ( 1: channels ), 'UniformOutput', false )';
set ( handles.popupIC,    'String', labels.ICs,    'Value', 1 )
set ( handles.popupTrial, 'String', labels.trials, 'Value', 1 )


% Enables the subject navigation buttons.
set ( handles.uibuttonSave, 'Enable', 'on' );
if current > 1,     set ( handles.buttonPrev, 'Enable', 'on' ), end
if current < files, set ( handles.buttonNext, 'Enable', 'on' ), end

% Enables the EOG, EKG and EMG buttons.
if any ( EOGidx ), set ( handles.toggleEOG,   'Enable', 'on' ), end
if any ( EKGidx ), set ( handles.toggleEKG,   'Enable', 'on' ), end
if any ( EMGidx ), set ( handles.toggleEMG,   'Enable', 'on' ), end

% If time data, enables the time/frequency toggle.
if ~isempty ( MEGtdata ), set ( handles.uitoggleTF,   'Enable', 'on' ), end

% Plots the data.
updateMulti ( handles )


function updateMulti ( handles )

% Gets the data for time data.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    MEGorig  = handles.current.data.tMEG;
    EOGdata  = handles.current.data.tEOG;
    EKGdata  = handles.current.data.tEKG;
    EMGdata  = handles.current.data.tEMG;
    
    yaxis    = handles.current.times;
    viewband = cat ( 2, min ( yaxis ), max ( yaxis ) );
    
% Gets the data for frequency data.
else
    MEGorig  = handles.current.data.fMEG;
    EOGdata  = handles.current.data.fEOG;
    EKGdata  = handles.current.data.fEKG;
    EMGdata  = handles.current.data.fEMG;
    
    yaxis    = handles.current.freqs;
    viewband = handles.config.viewband;
end

% Removes the discarded trials.
ktrials  = handles.current.trialtype == 0;
MEGorig  = MEGorig  ( :, :, ktrials );
EOGdata  = EOGdata  ( :, :, ktrials );
EKGdata  = EKGdata  ( :, :, ktrials );
EMGdata  = EMGdata  ( :, :, ktrials );

% Extracts the metadata.
mixing   = handles.current.mixing;
[ channels, samples, trials ] = size ( MEGorig );

% Gets the ICs' data using the mixing matrix.
ICorig   = pinv     ( mixing ) * reshape ( MEGorig, channels, [] );
ICorig   = reshape  ( ICorig, [], samples, trials );

if get ( handles.toggleKalima, 'Value' )
    
    rICs     = find ( handles.current.comptype > 0 );
    ICclean  = ICorig;
    
    % Removes a smoothed version of the discarded components.
    for a = 1: numel ( rICs )
        b = ICorig ( rICs ( a ), :, : );
        b = ifft ( b, samples, 2 );
        for t = 1: size ( b, 3 )
            b ( :, :, t ) = smooth ( b ( :, :, t ), 200, 'loess' );
        end
        b = fft ( b, samples, 2 );
        b = b ( :, 1: samples, : );
        ICclean ( rICs ( a ), :, : ) = ICorig ( rICs ( a ), :, : ) - b;
    end
else
    
    % Removes the discarded components.
    kICs     = ( handles.current.comptype == 0 );
    ICclean  = ICorig ( kICs, :, : );
    mixing   = mixing ( :, kICs );
end


% Gets the clean data from the clean ICs.
MEGclean = mixing * reshape ( ICclean, [], samples * trials );
MEGclean = reshape ( MEGclean, channels, samples, trials );

if ~numel ( ICclean  ), ICclean  = zeros ( size ( yaxis ) ); end
if ~numel ( MEGorig  ), MEGorig  = zeros ( size ( yaxis ) ); end
if ~numel ( MEGclean ), MEGclean = zeros ( size ( yaxis ) ); end

% If temporal data...
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    
    % Removes the frequency-space EOG and EKG.
    EOGfdata = nan ( size ( EOGdata ), 'single' );
    EKGfdata = nan ( size ( EKGdata ), 'single' );
    
% If frequency data...
else
    
    % Takes te absolute value.
    MEGorig  = abs ( MEGorig  );
    MEGclean = abs ( MEGclean );
    ICclean  = abs ( ICclean  );
    EOGfdata = abs ( EOGdata  );
    EKGfdata = abs ( EKGdata  );
    EMGdata  = abs ( EMGdata  );
end


% % Future work.
% MEGRO  = { 'MEG203*' 'MEG212*' 'MEG213*' 'MEG231*' 'MEG232*' 'MEG233*' 'MEG234*' 'MEG243*' 'MEG251*' 'MEG252*' 'MEG253*' 'MEG254*' };
% MEGLO  = { 'MEG164*' 'MEG171*' 'MEG172*' 'MEG173*' 'MEG174*' 'MEG191*' 'MEG192*' 'MEG193*' 'MEG194*' 'MEG204*' 'MEG211*' 'MEG214*' };
% MEGidx    = ft_channelselection ( MEGLO, handles.current.topolabel );
% MEGidx    = ismember ( handles.current.topolabel, MEGidx );
% MEGclean = MEGclean ( MEGidx, :, : );


% Gets the trial-separated clean data.
MEGtrials = squeeze ( mean ( MEGclean, 1 ) );

% Averages along trials (IC data) or channels (channels data).
ICclean   = nanmean ( ICclean, 3 );
MEGclean  = nanmean ( mean ( MEGclean, 1 ), 3 );
MEGorig   = nanmean ( mean ( MEGorig,  1 ), 3 );
EOGfdata  = nanmean ( mean ( EOGfdata, 1 ), 3 );
EKGfdata  = nanmean ( mean ( EKGfdata, 1 ), 3 );
EMGdata   = nanmean ( mean ( EMGdata,  1 ), 3 );

% Gets the residue.
residue   = MEGorig - MEGclean;


% Gets the maximum of each data group.
MEGmax   = 1.1 * max ( abs ( MEGtrials (:) ) ) + realmin ( 'single' );
ICsmax   = 1.1 * max ( abs ( ICclean   (:) ) ) + realmin ( 'single' );
ressmax  = 1.1 * max ( abs ( residue       ) ) + realmin ( 'single' );
cleanmax = 1.1 * max ( abs ( MEGclean      ) ) + realmin ( 'single' );
EOGfmax  = 1.1 * max ( abs ( EOGfdata      ) ) + realmin ( 'single' );
EKGfmax  = 1.1 * max ( abs ( EKGfdata      ) ) + realmin ( 'single' );
EMGmax   = 1.1 * max ( abs ( EMGdata       ) ) + realmin ( 'single' );

% In time visualization the minimum is minus the maximum.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    MEGmin   = -MEGmax;
    ICsmin   = -ICsmax;
    ressmin  = -ressmax;
    cleanmin = -cleanmax;
    
% In frequency visualization the minimum is 0.
else
    MEGmin   = 0;
    ICsmin   = 0;
    ressmin  = 0;
    cleanmin = 0;
end

% Corrects the amplitude of the EKG and EMG data.
EOGfdata = EOGfdata * ressmax / EOGfmax;
EKGfdata = EKGfdata * ressmax / EKGfmax;
EMGdata  = EMGdata  * cleanmax  / EMGmax;

% Destroys the not requiered data.
if ~get ( handles.toggleEOG,      'value' ), EOGfdata = nan ( size ( EOGfdata ), 'single' ); end
if ~get ( handles.toggleEKG,      'value' ), EKGfdata = nan ( size ( EKGfdata ), 'single' ); end
if ~get ( handles.toggleEMG,      'value' ), EMGdata  = nan ( size ( EMGdata  ), 'single' ); end
if ~get ( handles.toggleOriginal, 'value' ), MEGorig  = nan ( size ( MEGorig  ), 'single' ); end

% Initializes the line specification.
zeroline  = { 'LineStyle', ':', 'Color', [ 0.5 0.5 0.5 ], 'HandleVisibility', 'off' };
physline  = { 'LineStyle', '-', 'Color', [ 0.0 1.0 0.0 ] };
cleanline = { 'LineStyle', '-', 'Color', [ 0.0 0.0 0.0 ] };
origline  = { 'LineStyle', '-', 'Color', [ 0.9 0.0 0.0 ] };
noisyline = { 'LineStyle', '-', 'Color', [ 0.7 0.7 0.7 ] };

% Prepares the axes.
cla  ( handles.axesTrials );
cla  ( handles.axesICs );
cla  ( handles.axesRes );
cla  ( handles.axesMean );

set  ( handles.axesTrials, 'XLim', viewband )
set  ( handles.axesICs,    'XLim', viewband )
set  ( handles.axesRes,    'XLim', viewband )
set  ( handles.axesMean,   'XLim', viewband  )

set  ( handles.axesTrials, 'YLim', [ MEGmin   MEGmax   ] )
set  ( handles.axesICs,    'YLim', [ ICsmin   ICsmax   ] )
set  ( handles.axesRes,    'YLim', [ ressmin  ressmax  ] )
set  ( handles.axesMean,   'YLim', [ cleanmin cleanmax ] )

set  ( handles.axesTrials, 'YTick', [], 'XTickLabel', '' )
set  ( handles.axesICs,    'YTick', [], 'XTickLabel', '' )
set  ( handles.axesRes,    'YTick', [], 'XTickLabel', '' )
set  ( handles.axesMean,   'YTick', [], 'XTickLabel', '' )

% Draws a line at 0.
plot ( handles.axesTrials, [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )
plot ( handles.axesICs,    [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )
plot ( handles.axesRes,    [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )
plot ( handles.axesMean,   [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )

% Plots the data.
plot ( handles.axesTrials, yaxis, MEGtrials )

plot ( handles.axesICs,    yaxis, ICclean   )

plot ( handles.axesRes,    yaxis, EOGfdata, physline   {:} )
plot ( handles.axesRes,    yaxis, EKGfdata, physline   {:} )
plot ( handles.axesRes,    yaxis, residue,  cleanline  {:} )

plot ( handles.axesMean,   yaxis, EMGdata,  physline   {:} )
plot ( handles.axesMean,   yaxis, MEGorig,  origline   {:} )
plot ( handles.axesMean,   yaxis, MEGclean, cleanline  {:} )


% Plots the single IC and single trial data.
updateSingle ( handles )

% Re-scales the plots, if needed.
toggleICsGlobal_Callback    ( handles.toggleICsGlobal,    [], handles )
toggleTrialsGlobal_Callback ( handles.toggleTrialsGlobal, [], handles )
toggleMeanGlobal_Callback   ( handles.toggleMeanGlobal,   [], handles )
toggleResGlobal_Callback    ( handles.toggleResGlobal,    [], handles )


function updateSingle ( handles )

% Gets the data for time data.
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    MEGorig  = handles.current.data.tMEG;
    EOGdata  = handles.current.data.tEOG;
    EKGdata  = handles.current.data.tEKG;
    EMGdata  = handles.current.data.tEMG;
    
    yaxis    = handles.current.times;
    viewband = cat ( 2, min ( yaxis ), max ( yaxis ) );
    
% Gets the data for frequency data.
else
    MEGorig  = handles.current.data.fMEG;
    EOGdata  = handles.current.data.fEOG;
    EKGdata  = handles.current.data.fEKG;
    EMGdata  = handles.current.data.fEMG;
    
    yaxis    = handles.current.freqs;
    viewband = handles.config.viewband;
end

% Extracts the metadata.
mixing   = handles.current.mixing;
[ channels, samples, trials ] = size ( MEGorig );

% Gets the list of clean trials and ICs.
ktrials  = handles.current.trialtype == 0;
kICs     = handles.current.comptype  == 0;

% Gets the ICs' data using the mixing matrix.
ICorig   = pinv     ( mixing ) * reshape ( MEGorig, channels, [] );
ICorig   = reshape  ( ICorig, [], samples, trials );

% Gets the clean IC data removing the noisy trials.
ICclean  = ICorig   ( :, :, ktrials );

% Gets the clean MEG data removing the noisy ICs.
MEGclean = mixing ( :, kICs ) * reshape ( ICorig ( kICs, :, : ), [], samples * trials );
MEGclean = reshape  ( MEGclean, [], samples, trials );


% Gets the selected trial and IC.
trial    = get ( handles.popupTrial, 'Value' );
IC       = get ( handles.popupIC,    'Value' );

% Sets the type of the current trial and IC.
set ( handles.popupTrialType, 'Value', handles.current.trialtype ( trial ) + 1 )
set ( handles.popupICType,    'Value', handles.current.comptype  ( IC    ) + 1 )


% Initializes the data in case some data is not present.
if ~numel ( ICorig  ), ICorig  = nan ( size ( MEGorig ( 1, :, : ) ), 'single' ); end
if ~numel ( MEGorig ), MEGorig = nan ( size ( MEGorig ( 1, :, : ) ), 'single' ); end
if ~numel ( EOGdata ), EOGdata = nan ( size ( MEGorig ( 1, :, : ) ), 'single' ); end
if ~numel ( EKGdata ), EKGdata = nan ( size ( MEGorig ( 1, :, : ) ), 'single' ); end
if ~numel ( EMGdata ), EMGdata = nan ( size ( MEGorig ( 1, :, : ) ), 'single' ); end

% Gets the selected data.
ICorig   = ICorig   ( IC, :,     : );
ICclean  = ICclean  ( IC, :,     : );
MEGorig  = MEGorig  (  :, :, trial );
MEGclean = MEGclean (  :, :, trial );
EOGtdata = EOGdata  ( :,  :, trial );
EOGfdata = EOGdata  ( :,  :,     : );
EKGtdata = EKGdata  ( :,  :, trial );
EKGfdata = EKGdata  ( :,  :,     : );
EMGdata  = EMGdata  (  :, :, trial );

% If temporal data...
if strcmp ( get ( handles.uitoggleTF, 'State' ), 'off' )
    
    % Removes the frequency-space EOG and EKG.
    EOGfdata = nan ( size ( EOGfdata ), 'single' );
    EKGfdata = nan ( size ( EKGfdata ), 'single' );
    
% If frequency data...
else
    
    % Takes te absolute value.
    ICorig   = abs ( ICorig   );
    ICclean  = abs ( ICclean  );
    MEGorig  = abs ( MEGorig  );
    MEGclean = abs ( MEGclean );
    EOGfdata = abs ( EOGfdata );
    EKGfdata = abs ( EKGfdata );
    EMGdata  = abs ( EMGdata  );
    
    % Removes the time-space EOG and EKG.
    EOGtdata = nan ( size ( EOGtdata ), 'single' );
    EKGtdata = nan ( size ( EKGtdata ), 'single' );
end

% Averages along trials (ICs) or channels (trials).
ICorig   = squeeze ( nanmean ( ICorig,   3 ) );
ICclean  = squeeze ( nanmean ( ICclean,  3 ) );
MEGorig  = squeeze ( nanmean ( MEGorig,  1 ) );
MEGclean = squeeze ( nanmean ( MEGclean, 1 ) );
EOGfdata = squeeze ( nanmean ( EOGfdata, 3 ) );
EKGfdata = squeeze ( nanmean ( EKGfdata, 3 ) );
EMGdata  = squeeze ( nanmean ( EMGdata,  1 ) );

% Gets the maximum of each data group.
ICmax    = 1.1 * max ( abs ( ICorig   ) ) + realmin ( 'single' );
MEGmax   = 1.1 * max ( abs ( MEGorig  ) ) + realmin ( 'single' );
EOGtmax  = 1.1 * max ( abs ( EOGtdata ) ) + realmin ( 'single' );
EOGfmax  = 1.1 * max ( abs ( EOGfdata ) ) + realmin ( 'single' );
EKGtmax  = 1.1 * max ( abs ( EKGtdata ) ) + realmin ( 'single' );
EKGfmax  = 1.1 * max ( abs ( EKGfdata ) ) + realmin ( 'single' );
EMGmax   = 1.1 * max ( abs ( EMGdata  ) ) + realmin ( 'single' );

% Corrects the amplitude of the physiological data.
EOGtdata = EOGtdata * MEGmax / EOGtmax;
EOGfdata = EOGfdata * ICmax  / EOGfmax;
EKGtdata = EKGtdata * MEGmax / EKGtmax;
EKGfdata = EKGfdata * ICmax  / EKGfmax;
EMGdata  = EMGdata  * MEGmax / EMGmax;


% Destroys the not requiered data.
if ~get ( handles.toggleEOG,            'value' ), EOGtdata = nan ( size ( EOGtdata ), 'single' ); end
if ~get ( handles.toggleEOG,            'value' ), EOGfdata = nan ( size ( EOGfdata ), 'single' ); end
if ~get ( handles.toggleEKG,            'value' ), EKGtdata = nan ( size ( EKGtdata ), 'single' ); end
if ~get ( handles.toggleEKG,            'value' ), EKGfdata = nan ( size ( EKGfdata ), 'single' ); end
if ~get ( handles.toggleEMG,            'value' ), EMGdata  = nan ( size ( EMGdata  ), 'single' ); end
if ~get ( handles.toggleTrialsOriginal, 'value' ), MEGorig  = nan ( size ( MEGorig  ), 'single' ); end
if ~get ( handles.toggleICsOriginal,    'value' ), ICorig   = nan ( size ( ICorig   ), 'single' ); end


% Initializes the line specification.
zeroline  = { 'LineStyle', ':', 'Color', [ 0.5 0.5 0.5 ], 'HandleVisibility', 'off' };
physline  = { 'LineStyle', '-', 'Color', [ 0.0 1.0 0.0 ] };
cleanline = { 'LineStyle', '-', 'Color', [ 0.0 0.0 0.0 ] };
origline  = { 'LineStyle', '-', 'Color', [ 0.9 0.0 0.0 ] };
noisyline = { 'LineStyle', '-', 'Color', [ 0.7 0.7 0.7 ] };


% Colors the component red, if removed.
if get ( handles.popupICType, 'Value' ) == 1
    IColine = origline;
    ICcline = cleanline;
else
    IColine = noisyline;
    ICcline = noisyline;
end

% Colors the trial red, if removed.
if get ( handles.popupTrialType, 'Value' ) == 1
    trialoline = origline;
    trialcline = cleanline;
else
    trialoline = origline;
    trialcline = noisyline;
end

% Prepares the axes.
cla  ( handles.axesIC );
cla  ( handles.axesTrial );

set  ( handles.axesIC,    'XLim', viewband )
set  ( handles.axesTrial, 'XLim', viewband )

set  ( handles.axesIC,    'YTick', [], 'XTickLabel', '' )
set  ( handles.axesTrial, 'YTick', [], 'XTickLabel', '' )

% Draws a line at 0.
plot ( handles.axesTrial, [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )
plot ( handles.axesIC,    [ 0 0 0 ], [ -1e10 0 1e10 ], zeroline {:} )

% Plots the data.
plot ( handles.axesTrial, yaxis, EOGtdata, physline   {:} )
plot ( handles.axesTrial, yaxis, EKGtdata, physline   {:} )
plot ( handles.axesTrial, yaxis, EMGdata,  physline   {:} )
plot ( handles.axesTrial, yaxis, MEGorig,  trialoline {:} )
plot ( handles.axesTrial, yaxis, MEGclean, trialcline {:} )

plot ( handles.axesIC,    yaxis, EOGfdata, physline   {:} )
plot ( handles.axesIC,    yaxis, EKGfdata, physline   {:} )
plot ( handles.axesIC,    yaxis, ICorig,   physline   {:} )
plot ( handles.axesIC,    yaxis, ICorig,   IColine    {:} )
plot ( handles.axesIC,    yaxis, ICclean , ICcline    {:} )

% Re-scales the plots, if needed.
toggleICsGlobal_Callback    ( handles.toggleICsGlobal,     [], handles )
toggleTrialsGlobal_Callback ( handles.toggleTrialsGlobal,  [], handles )

% Updates the subject information.
updateInfo ( handles )

guidata ( handles.ICsViewer, handles );


function updateInfo ( handles )

% Gets the current file information.
subject     = handles.current.subject;
task        = handles.current.task;
stage       = handles.current.stage;
channel     = handles.current.channel;
updated     = handles.current.updated;

% Gets the global information.
index       = handles.data.current;
files       = numel ( handles.data.filename );
folder      = fullpath ( handles.data.folder );
filename    = handles.data.filename { handles.data.current };

% Gets the clean trial and ICs information.
ICs         = numel ( handles.current.comptype  );
trials      = numel ( handles.current.trialtype );
cleanICs    = sum ( handles.current.comptype  == 0 );
cleantrials = sum ( handles.current.trialtype == 0 );

% Updates the information text.
if ~isempty ( stage )
    handles.current.info {1} = sprintf ( 'Subject ''%s'', task ''%s'', stage ''%s'', channel group ''%s'' (file %i of a total of %i).', subject, task, stage, channel, index, files );
else
    handles.current.info {1} = sprintf ( 'Subject ''%s'', task ''%s'', channel group ''%s'' (file %i of a total of %i).', subject, task, channel, index, files );
end
handles.current.info {2} = sprintf ( 'Full route to file: %s%s.', folder, filename );
handles.current.info {3} = sprintf ( 'Last time saved: %s.', updated );
handles.current.info {4} = sprintf ( '%.0f of %.0f trials. %.0f of %.0f independent components.', cleantrials, trials, cleanICs, ICs );

set ( handles.textInfoA, 'String', handles.current.info {1} );
set ( handles.textInfoB, 'String', handles.current.info {2} );
set ( handles.textInfoC, 'String', handles.current.info {3} );
set ( handles.textInfoD, 'String', handles.current.info {4} );


function savedata ( handles )

% Temporarily disables the subject navigation buttons.
set ( handles.buttonPrev,   'Enable', 'off' );
set ( handles.buttonNext,   'Enable', 'off' );
set ( handles.uibuttonSave, 'Enable', 'off' );
drawnow

% Gets information on the files.
folder                 = handles.data.folder;
files                  = handles.data.filename;
current                = handles.data.current;

% Loads the old data from the file.
filename               = sprintf ( '%s%s', folder, files { current } );
taskdata               = load ( filename );

% Stores the new trial and component types.
cleaninfo              = taskdata.cleaninfo;
cleaninfo.trial.types  = handles.config. trialtypes;
cleaninfo.trial.type   = handles.current.trialtype;
cleaninfo.comp. types  = handles.config. comptypes;
cleaninfo.comp. type   = handles.current.comptype;

% Stores the date.
updated                = datestr ( now );

% Saves the new data.
taskdata.cleaninfo     = cleaninfo;
taskdata.updated       = updated;

save ( '-v6', filename, '-struct', 'taskdata' )

% Updates the date in the handles structure.
handles.current.updated = updated;
guidata ( handles.ICsViewer, handles )

% Updates the file information.
updateInfo ( handles )

% Enables the subject navigation buttons.
set ( handles.uibuttonSave, 'Enable', 'on' );
if current > 1
    set ( handles.buttonPrev, 'Enable', 'on' );
end
if current < numel ( files )
    set ( handles.buttonNext, 'Enable', 'on' );
end
drawnow


function popupTrial_KeyPressFcn ( hObject, eventdata, handles )

% Gets the pressed key.
key     = eventdata.Key;
if ( strncmp ( key, 'numpad', 6 ) ), key = key ( 7: end ); end
keyval  = NaN;

% If it is a number sets the IC type to it.
if isfinite ( str2double ( key ) ) && str2double ( key ) >= 1 && str2double ( key ) <= numel ( handles.config.trialtypes )
    keyval  = str2double ( key );
end

% If it is an arrow, sets the IC type to the next or previous one.
if strcmp ( key, 'rightarrow' ), keyval = get ( handles.popupTrialType, 'Value' ) + 1; end
if strcmp ( key, 'leftarrow' ),  keyval = get ( handles.popupTrialType, 'Value' ) - 1; end

% Circles if needed.
if keyval > numel ( handles.config.trialtypes ), keyval = 1; end
if keyval < 1, keyval = numel ( handles.config.trialtypes ); end

% Sets the IC type.
if isfinite ( keyval )
    set ( handles.popupTrialType, 'Value', keyval );
    
    % Updates the information.
    popupTrialType_Callback ( handles.popupTrialType, [], handles );
end


function popupIC_KeyPressFcn    ( hObject, eventdata, handles )

% Gets the pressed key.
key     = eventdata.Key;
if ( strncmp ( key, 'numpad', 6 ) ), key = key ( 7: end ); end
keyval  = NaN;

% If it is a number sets the IC type to it.
if isfinite ( str2double ( key ) ) && str2double ( key ) >= 1 && str2double ( key ) <= numel ( handles.config.comptypes )
    keyval  = str2double ( key );
end

% If it is an arrow, sets the IC type to the next or previous one.
if strcmp ( key, 'rightarrow' ), keyval = get ( handles.popupICType, 'Value' ) + 1; end
if strcmp ( key, 'leftarrow' ),  keyval = get ( handles.popupICType, 'Value' ) - 1; end

% Circles if needed.
if keyval > numel ( handles.config.comptypes ), keyval = 1; end
if keyval < 1, keyval = numel ( handles.config.comptypes ); end

% Sets the IC type.
if isfinite ( keyval )
    set ( handles.popupICType, 'Value', keyval );
    
    % Updates the information.
    popupICType_Callback ( handles.popupICType, [], handles );
end


function s6_selectICsAndTrials_OutputFcn ( hObject, eventdata, handles )

