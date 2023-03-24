function cfg = my_databrowser ( cfg, data )

% FT_DATABROWSER can be used for visual inspection of data. Artifacts that were
% detected by artifact functions (see FT_ARTIFACT_xxx functions where xxx is the type
% of artifact) are marked. Additionally data pieces can be marked and unmarked as
% artifact by manual selection. The output cfg contains the updated specification of
% the artifacts.
%
% Use as
%   cfg = ft_databrowser(cfg)
%   cfg = ft_databrowser(cfg, data)
% If you only specify the configuration structure, it should contains the name of the
% dataset on your hard disk (see below). If you specify input data, it should be a
% data structure as obtained from FT_PREPROCESSING or from FT_COMPONENTANALYSIS.
%
% If you want to browse data that is on disk, you have to specify
%   cfg.dataset                 = string with the filename
% Instead of specifying the dataset, you can also explicitely specify the name of the
% file containing the header information and the name of the file containing the
% data, using
%   cfg.datafile                = string with the filename
%   cfg.headerfile              = string with the filename
%
% The following configuration options are supported:
%   cfg.ylim                    = vertical scaling, can be 'maxmin', 'maxabs' or [ymin ymax] (default = 'maxabs')
%   cfg.zlim                    = color scaling to apply to component topographies, 'minmax', 'maxabs' (default = 'maxmin')
%   cfg.blocksize               = duration in seconds for cutting the data up
%   cfg.trl                     = structure that defines the data segments of interest, only applicable for trial-based data
%   cfg.continuous              = 'yes' or 'no' whether the data should be interpreted as continuous or trial-based
%   cfg.channel                 = cell-array with channel labels, see FT_CHANNELSELECTION
%   cfg.plotlabels              = 'yes' (default), 'no', 'some'; whether to plot channel labels in vertical
%                                 viewmode ('some' plots one in every ten labels; useful when plotting a
%                                 large number of channels at a time)
%   cfg.ploteventlabels         = 'type=value', 'colorvalue' (default = 'type=value');
%   cfg.viewmode                = string, 'butterfly', 'vertical', 'component' for visualizing components e.g. from an ICA (default is 'butterfly')
%   cfg.artfctdef.xxx.artifact  = Nx2 matrix with artifact segments see FT_ARTIFACT_xxx functions
%   cfg.selectfeature           = string, name of feature to be selected/added (default = 'visual')
%   cfg.selectmode              = 'markartifact', 'markpeakevent', 'marktroughevent' (default = 'markartifact')
%   cfg.colorgroups             = 'sequential' 'allblack' 'labelcharx' (x = xth character in label), 'chantype' or
%                                  vector with length(data/hdr.label) defining groups (default = 'sequential')
%   cfg.channelcolormap         = COLORMAP (default = customized lines map with 15 colors)
%   cfg.selfun                  = string, name of function which is evaluated using the right-click context menu
%                                  The selected data and cfg.selcfg are passed on to this function.
%   cfg.selcfg                  = configuration options for function in cfg.selfun
%   cfg.seldat                  = 'selected' or 'all', specifies whether only the currently selected or all channels
%                                 will be passed to the selfun (default = 'selected')
%   cfg.renderer                = string, 'opengl', 'zbuffer', 'painters', see MATLAB Figure Properties.
%                                 If the databrowser crashes, set to 'painters'.
%
% The following options for the scaling of the EEG, EOG, ECG, EMG and MEG channels is
% optional and can be used to bring the absolute numbers of the different channel
% types in the same range (e.g. fT and uV). The channel types are determined from the
% input data using FT_CHANNELSELECTION.
%   cfg.eegscale                = number, scaling to apply to the EEG channels prior to display
%   cfg.eogscale                = number, scaling to apply to the EOG channels prior to display
%   cfg.ecgscale                = number, scaling to apply to the ECG channels prior to display
%   cfg.emgscale                = number, scaling to apply to the EMG channels prior to display
%   cfg.megscale                = number, scaling to apply to the MEG channels prior to display
%   cfg.gradscale               = number, scaling to apply to the MEG gradiometer channels prior to display (in addition to the cfg.megscale factor)
%   cfg.magscale                = number, scaling to apply to the MEG magnetometer channels prior to display (in addition to the cfg.megscale factor)
%   cfg.mychanscale             = number, scaling to apply to the channels specified in cfg.mychan
%   cfg.mychan                  = Nx1 cell-array with selection of channels
%   cfg.chanscale               = Nx1 vector with scaling factors, one per channel specified in cfg.channel
%   cfg.compscale               = string, 'global' or 'local', defines whether the colormap for the topographic scaling is
%                                 applied per topography or on all visualized components (default 'global')
%
% You can specify preprocessing options that are to be applied to the  data prior to
% display. Most options from FT_PREPROCESSING are supported. They should be specified
% in the sub-structure cfg.preproc like these examples
%   cfg.preproc.lpfilter        = 'no' or 'yes'  lowpass filter (default = 'no')
%   cfg.preproc.lpfreq          = lowpass  frequency in Hz
%   cfg.preproc.demean          = 'no' or 'yes', whether to apply baseline correction (default = 'no')
%   cfg.preproc.detrend         = 'no' or 'yes', remove linear trend from the data (done per trial) (default = 'no')
%   cfg.preproc.baselinewindow  = [begin end] in seconds, the default is the complete trial (default = 'all')
%
% In case of component viewmode, a layout is required. If no layout is specified, an
% attempt is made to construct one from the sensor definition that is present in the
% data or specified in the configuration.
%   cfg.layout                  = filename of the layout, see FT_PREPARE_LAYOUT
%   cfg.elec                    = structure with electrode positions, see FT_DATATYPE_SENS
%   cfg.grad                    = structure with gradiometer definition, see FT_DATATYPE_SENS
%   cfg.elecfile                = name of file containing the electrode positions, see FT_READ_SENS
%   cfg.gradfile                = name of file containing the gradiometer definition, see FT_READ_SENS
%
% The default font size might be too small or too large, depending on the number of
% channels. You can use the following options to change the size of text inside the
% figure and along the axes.
%   cfg.fontsize                = number, fontsize inside the figure (default = 0.03)
%   cfg.fontunits               = string, can be 'normalized', 'points', 'pixels', 'inches' or 'centimeters' (default = 'normalized')
%   cfg.axisfontsize            = number, fontsize along the axes (default = 10)
%   cfg.axisfontunits           = string, can be 'normalized', 'points', 'pixels', 'inches' or 'centimeters' (default = 'points')
%   cfg.linewidth               = number, width of plotted lines (default = 0.5)
%
% When visually selection data, a right-click will bring up a context-menu containing
% functions to be executed on the selected data. You can use your own function using
% cfg.selfun and cfg.selcfg. You can use multiple functions by giving the names/cfgs
% as a cell-array.
%
% In butterfly mode, you can use the "identify" button to reveal the name of a
% channel. Please be aware that it searches only vertically. This means that it will
% return the channel with the amplitude closest to the point you have clicked at the
% specific time point. This might be counterintuitive at first.
%
% The "cfg.artifact" field in the output cfg is a Nx2 matrix comparable to the
% "cfg.trl" matrix of FT_DEFINETRIAL. The first column of which specifying the
% beginsamples of an artifact period, the second column contains the endsamples of
% the artifactperiods.
%
% Note for debugging: in case the databrowser crashes, use delete(gcf) to kill the
% figure.
%
% See also FT_PREPROCESSING, FT_REJECTARTIFACT, FT_ARTIFACT_EOG, FT_ARTIFACT_MUSCLE,
% FT_ARTIFACT_JUMP, FT_ARTIFACT_MANUAL, FT_ARTIFACT_THRESHOLD, FT_ARTIFACT_CLIP,
% FT_ARTIFACT_ECG, FT_COMPONENTANALYSIS
% 
% This function requires FieldTrip 20160222 or newer to work properly.

% Based on FieldTrip 20160222 functions:
% * ft_databrowser by Robert Oostenveld & Ingrid Nieuwenhuis


hasdata = nargin > 1;
hascomp = hasdata && ft_datatype ( data, 'comp' );

% for backward compatibility
cfg = ft_checkconfig(cfg, 'unused',     {'comps', 'inputfile', 'outputfile'});
cfg = ft_checkconfig(cfg, 'renamed',    {'zscale', 'ylim'});
cfg = ft_checkconfig(cfg, 'renamedval', {'ylim', 'auto', 'maxabs'});
cfg = ft_checkconfig(cfg, 'renamedval', {'selectmode', 'mark', 'markartifact'});

% ensure that the preproc specific options are located in the cfg.preproc substructure
cfg = ft_checkconfig(cfg, 'createsubcfg',  {'preproc'});

% set the defaults
cfg.ylim            = ft_getopt(cfg, 'ylim', 'maxabs');
cfg.artfctdef       = ft_getopt(cfg, 'artfctdef', struct);
cfg.selectfeature   = ft_getopt(cfg, 'selectfeature','visual');     % string or cell-array
cfg.selectmode      = ft_getopt(cfg, 'selectmode', 'markartifact');
cfg.blocksize       = ft_getopt(cfg, 'blocksize');                 % now used for both continuous and non-continuous data, defaulting done below
cfg.preproc         = ft_getopt(cfg, 'preproc');                   % see preproc for options
cfg.selfun          = ft_getopt(cfg, 'selfun');                    % default functions: 'simpleFFT', 'multiplotER', 'topoplotER', 'topoplotVAR', 'movieplotER'
cfg.selcfg          = ft_getopt(cfg, 'selcfg');                    % defaulting done below, requires layouts/etc to be processed
cfg.seldat          = ft_getopt(cfg, 'seldat', 'current');
cfg.colorgroups     = ft_getopt(cfg, 'colorgroups', 'sequential');
cfg.channelcolormap = ft_getopt(cfg, 'channelcolormap', [0.75 0 0;0 0 1;0 1 0;0.44 0.19 0.63;0 0.13 0.38;0.5 0.5 0.5;1 0.75 0;1 0 0;0.89 0.42 0.04;0.85 0.59 0.58;0.57 0.82 0.31;0 0.69 0.94;1 0 0.4;0 0.69 0.31;0 0.44 0.75]);
cfg.eegscale        = ft_getopt(cfg, 'eegscale');
cfg.eogscale        = ft_getopt(cfg, 'eogscale');
cfg.ecgscale        = ft_getopt(cfg, 'ecgscale');
cfg.emgscale        = ft_getopt(cfg, 'emgscale');
cfg.megscale        = ft_getopt(cfg, 'megscale');
cfg.magscale        = ft_getopt(cfg, 'magscale');
cfg.gradscale       = ft_getopt(cfg, 'gradscale');
cfg.chanscale       = ft_getopt(cfg, 'chanscale');
cfg.mychanscale     = ft_getopt(cfg, 'mychanscale');
cfg.layout          = ft_getopt(cfg, 'layout');
cfg.plotlabels      = ft_getopt(cfg, 'plotlabels', 'yes');
cfg.event           = ft_getopt(cfg, 'event');                       % this only exists for backward compatibility and should not be documented
cfg.continuous      = ft_getopt(cfg, 'continuous');                  % the default is set further down in the code, conditional on the input data
cfg.ploteventlabels = ft_getopt(cfg, 'ploteventlabels', 'type=value');
cfg.precision       = ft_getopt(cfg, 'precision', 'double');
cfg.zlim            = ft_getopt(cfg, 'zlim', 'maxmin');
cfg.compscale       = ft_getopt(cfg, 'compscale', 'global');
cfg.renderer        = ft_getopt(cfg, 'renderer', get ( 0, 'DefaultFigureRenderer' ));
cfg.fontsize        = ft_getopt(cfg, 'fontsize', 0.03);
cfg.fontunits       = ft_getopt(cfg, 'fontunits', 'normalized');     % inches, centimeters, normalized, points, pixels
cfg.editfontsize    = ft_getopt(cfg, 'editfontsize', 12);
cfg.editfontunits   = ft_getopt(cfg, 'editfontunits', 'points');     % inches, centimeters, normalized, points, pixels
cfg.axisfontsize    = ft_getopt(cfg, 'axisfontsize', 10);
cfg.axisfontunits   = ft_getopt(cfg, 'axisfontunits', 'points');     % inches, centimeters, normalized, points, pixels
cfg.linewidth       = ft_getopt(cfg, 'linewidth', 0.5);

cfg.physio          = ft_getopt ( cfg, 'physio', [] );
cfg.badchan         = ft_getopt ( cfg, 'badchan', {} );
cfg.bgcolor         = ft_getopt ( cfg, 'bgcolor', [ 1 1 1 ] );
cfg.projinfo        = ft_getopt ( cfg, 'projinfo', [] );
cfg.applyprojector  = ft_getopt ( cfg, 'applyprojector', false );
cfg.showevent       = ft_getopt ( cfg, 'showevent', true );

if ~isempty(cfg.chanscale)
  if ~isfield(cfg, 'channel')
    warning('ignoring cfg.chanscale; this should only be used when an explicit channel selection is being made');
    cfg.chanscale = [];
  elseif numel(cfg.channel) ~= numel(cfg.chanscale)
    error('cfg.chanscale should have the same number of elements as cfg.channel');
  end

  % make sure chanscale is a column vector, not a row vector
  if size(cfg.chanscale,2) > size(cfg.chanscale,1)
    cfg.chanscale = cfg.chanscale';
  end
end

% Determines the number of channels to show, if required.
if ~isfield ( cfg, 'channel' )
    if hascomp
        cfg.channel = 1: min ( 10, size ( data.topo, 2 ) );
    else
        cfg.channel = 'all';
    end
end

% Determines the viewing mode, if required.
if ~isfield ( cfg, 'viewmode' )
    if hascomp
        cfg.viewmode = 'component';
    else
        cfg.viewmode = 'butterfly';
    end
end

if strcmp ( cfg.viewmode, 'component' )
    datatype = 'component';
else
    datatype = 'channel';
end


% Checks the input.
if hasdata
    
    % Checks that the data is valid.
    data = ft_checkdata ( data, 'datatype', {'raw+comp', 'raw'}, 'feedback', 'no', 'hassampleinfo', 'yes' );
    
%     % Gets the header from the data.
%     hdr  = ft_fetch_header ( data );
    
    % Creates the header from the data.
    hdr        = [];
    hdr.label  = data.label;
    hdr.Fs     = data.fsample;
    hdr.nChans = numel ( hdr.label );
    if isfield ( hdr, 'grad' )
        hdr.grad   = data.grad;
    end
    if isfield ( hdr, 'elec' )
        hdr.elec   = data.elec;
    end
else
    
    % Checks that the options are valid.
    cfg = ft_checkconfig ( cfg, 'dataset2files', 'yes');
    cfg = ft_checkconfig ( cfg, 'required',   {'headerfile', 'datafile' } );
    cfg = ft_checkconfig ( cfg, 'renamed',    {'datatype',   'continuous' } );
    cfg = ft_checkconfig ( cfg, 'renamedval', {'continuous', 'continuous', 'yes' } );
    
    % Initializes the data.
    data = [];
    
    % Gets the header from the file.
    hdr  = ft_read_header ( cfg.headerfile, 'headerformat', cfg.headerformat );
end


% Determines the type of system.
if isfield ( hdr, 'grad' ) && isfield ( hdr.grad, 'type' )
    senstype = hdr.grad.type;
else
    senstype = ft_senstype ( hdr.label );
end

% Determines the type of the channels.
chantype.eeg      = ft_channelselection ( 'EEG',       hdr.label, senstype );
chantype.eog      = ft_channelselection ( 'EOG',       hdr.label, senstype );
chantype.ecg      = ft_channelselection ( 'ECG',       hdr.label, senstype );
chantype.emg      = ft_channelselection ( 'EMG',       hdr.label, senstype );
chantype.meg      = ft_channelselection ( 'MEG',       hdr.label, senstype );
chantype.megmag   = ft_channelselection ( 'MEGMAG',    hdr.label, senstype );
chantype.meggrad  = ft_channelselection ( 'MEGGRAD',   hdr.label, senstype );
% chantype.selected = ft_channelselection ( cfg.channel, hdr.label, senstype );
% chantype.mychan   = ft_channelselection ( cfg.mychan,  hdr.label, senstype );


% Generates the layout to plot the component's topography.
if strcmp ( cfg.viewmode, 'component' )
    if ~isempty ( cfg.layout )
        
        % Uses the speciafied layout.
        tmpcfg        = [];
        tmpcfg.layout = cfg.layout;
        cfg.layout    = ft_prepare_layout ( tmpcfg );
    else
        warning ( 'No layout specified. Triying to generate a layout from channel positions.' );
        
        % Generates a layout from the channel positions.
        tmpcfg        = [];
        if isfield ( cfg, 'elec' ),     tmpcfg.elec     = cfg.elec;     end
        if isfield ( cfg, 'grad' ),     tmpcfg.grad     = cfg.grad;     end
        if isfield ( cfg, 'elecfile' ), tmpcfg.elecfile = cfg.elecfile; end
        if isfield ( cfg, 'gradfile' ), tmpcfg.gradfile = cfg.gradfile; end
        
        if hasdata
            cfg.layout = ft_prepare_layout ( tmpcfg, data );
        else
            cfg.layout = ft_prepare_layout ( tmpcfg );
        end
    end
end


% Initializes the event structure.
event = struct ( 'type', {}, 'sample', {}, 'value', {}, 'offset', {}, 'duration', {} );

% Gets the real events.
if ~hasdata
    event = ft_read_event ( cfg.dataset );
elseif isfield ( data, 'cfg' ) && ~isempty ( ft_findcfg ( data.cfg, 'origfs' ) )
    warning ( 'The data has been resampled, not showing the events.' );
elseif isfield ( data, 'cfg' ) && isfield ( data.cfg, 'event' )
    event = data.cfg.event;
elseif ~isempty ( cfg.event )
    event = cfg.event;
end


% Adds the selected artifact type, if needed.
if ~isempty ( cfg.selectfeature )
    
    % Makes sure that the names are in cell arrays.
    cfg.selectfeature = cellstr ( cfg.selectfeature );
    
    % Gets the list of new artifact types.
    newarts = setdiff ( cfg.selectfeature, fieldnames ( cfg.artfctdef ) );
    
    % Creates the new artifacts, if required.
    for aindex = 1: numel ( newarts )
        cfg.artfctdef.( newarts { aindex } ).artifact = zeros ( 0, 2 );
    end
end


% Determines if the data is continuous or epoched.
if hasdata
    if isempty ( cfg.continuous )
        if numel ( data.trial ) == 1 && ~ft_datatype ( data, 'timelock' )
            cfg.continuous = 'yes';
        else
            cfg.continuous = 'no';
        end
    end
else
    if isempty ( cfg.continuous )
        if hdr.nTrials == 1
            cfg.continuous = 'yes';
        else
            cfg.continuous = 'no';
        end
    end
end

% Selects the viewing mode.
if strcmp ( cfg.continuous, 'yes' )
    viewmode = 'segment';
else
    viewmode = 'trial';
end


% Gets (or generates) the trial definition.
if hasdata
    
    % Constructs the trl from the sample information and the time vectors.
    trlorg = single ( data.sampleinfo );
    trlorg ( :, 3 ) = round ( cellfun ( @(x) x (1), data.time (:) ) * data.fsample );
else
    
    % Gets the number of trials.
    if strcmp ( cfg.continuous, 'yes' )
        Ntrials = 1;
    else
        Ntrials = hdr.nTrials;
    end
    
    % FIXME in case of continuous=yes the trl should be [1 hdr.nSamples*nTrials 0]
    % and a scrollbar should be used
    
    % Constructs the trl matrix.
    trlorg = bsxfun ( @plus, [ 1 hdr.nSamples ], ( 0: Ntrials - 1 )' * hdr.nSamples );
    trlorg ( :, 3 ) = 0;
end

% Rewrites epoched data as continuous, if requested.
if strcmp ( cfg.continuous, 'yes' ) && numel ( data.trial ) > 1
    warning ( 'Interpreting trial-based data as continous, time axis is no longer appropriate.' )
    trlorg = cat ( 2, min ( trlorg ( :, 1 ) ), max ( trlorg ( :, 2  ) ), 0 );
end

% Determines the block size, if needed.
if isempty ( cfg.blocksize )
    if strcmp ( cfg.continuous, 'no' )
        cfg.blocksize = ( trlorg ( 1, 2 ) - trlorg ( 1, 1 ) + 1 ) ./ hdr.Fs;
    else
        cfg.blocksize = 1;
    end
end

% FIXME make a check for the consistency of cfg.continous, cfg.blocksize, cfg.trl and the data header


% Gets the list of channels to show (without phi�ysiological channels).
chanlabel = hdr.label;
chanlabel ( cfg.physio ) = [];
cfg.channel = ft_channelselection ( cfg.channel, chanlabel );
chansel     = match_str ( hdr.label, cfg.channel );

if isempty ( chansel ), error ( 'No channels to display.' ), end
if isempty ( trlorg  ), error ( 'No trials to display.' ),   end


% determine the vertical scaling
if ischar(cfg.ylim)
  if hasdata
    % the first trial is used to determine the vertical scaling
    dat = data.trial{1}(chansel,:);
  else
    % one second of data is read from file to determine the vertical scaling
    dat = ft_read_data(cfg.datafile, 'header', hdr, 'begsample', 1, 'endsample', round(hdr.Fs), 'chanindx', chansel, 'checkboundary', strcmp(cfg.continuous, 'no'), 'dataformat', cfg.dataformat, 'headerformat', cfg.headerformat);
  end % if hasdata
  % convert the data to another numeric precision, i.e. double, single or int32
  if ~isempty(cfg.precision)
    dat = cast(dat, cfg.precision);
  end
  minval = min(dat(:));
  maxval = max(dat(:));
  switch cfg.ylim
    case 'maxabs'
      maxabs   = max(abs([minval maxval]));
      scalefac = 10^(fix(log10(maxabs)));
      maxabs   = (round(maxabs / scalefac * 100) / 100) * scalefac;
      cfg.ylim = [-maxabs maxabs];
    case 'maxmin'
      cfg.ylim = [minval maxval];
    otherwise
      error('unsupported value for cfg.ylim');
  end % switch ylim
  % zoom in a bit when viemode is vertical
  if strcmp(cfg.viewmode, 'vertical')
    cfg.ylim = cfg.ylim/10;
  end
else
  if (numel(cfg.ylim) ~= 2) || ~isnumeric(cfg.ylim)
    error('cfg.ylim needs to be a 1x2 vector [ymin ymax], describing the upper and lower limits')
  end
end


% determine coloring of channels
if hasdata
  labels_all = data.label;
else
  labels_all = hdr.label;
end
if size(cfg.channelcolormap,2) ~= 3
  error('cfg.channelcolormap is not valid, size should be Nx3')
end

if isnumeric(cfg.colorgroups)
  % groups defined by user
  if length(labels_all) ~= length(cfg.colorgroups)
    error('length(cfg.colorgroups) should be length(data/hdr.label)')
  end
  R = cfg.channelcolormap(:,1);
  G = cfg.channelcolormap(:,2);
  B = cfg.channelcolormap(:,3);
  chancolors = [R(cfg.colorgroups(:)) G(cfg.colorgroups(:)) B(cfg.colorgroups(:))];

elseif strcmp(cfg.colorgroups, 'allblack')
  chancolors = zeros(length(labels_all),3);

elseif strcmp(cfg.colorgroups, 'chantype')
  type = ft_chantype(labels_all);
  [tmp, ~, cfg.colorgroups] = unique(type);
  fprintf('%3d colorgroups were identified\n',length(tmp))
  R = cfg.channelcolormap(:,1);
  G = cfg.channelcolormap(:,2);
  B = cfg.channelcolormap(:,3);
  chancolors = [R(cfg.colorgroups(:)) G(cfg.colorgroups(:)) B(cfg.colorgroups(:))];

elseif strcmp(cfg.colorgroups(1:9), 'labelchar')
  % groups determined by xth letter of label
  labelchar_num = str2double(cfg.colorgroups(10));
  vec_letters = num2str(zeros(length(labels_all),1));
  for iChan = 1:length(labels_all)
    vec_letters(iChan) = labels_all{iChan}(labelchar_num);
  end
  [tmp, ~, cfg.colorgroups] = unique(vec_letters);
  fprintf('%3d colorgroups were identified\n',length(tmp))
  R = cfg.channelcolormap(:,1);
  G = cfg.channelcolormap(:,2);
  B = cfg.channelcolormap(:,3);
  chancolors = [R(cfg.colorgroups(:)) G(cfg.colorgroups(:)) B(cfg.colorgroups(:))];

elseif strcmp(cfg.colorgroups, 'sequential')
  % no grouping
  chancolors = lines(length(labels_all));

else
  error('do not understand cfg.colorgroups')
end





% Gets the number of samples in the original data.
datasamples        = max ( trlorg (:) );

% Gets the artifact labels
artlabel           = fieldnames ( cfg.artfctdef );

% Gets the artifacts in a cell form.
artifact           = struct2cell ( cfg.artfctdef );
artifact           = cat ( 1, artifact {:} );
artifact           = { artifact.artifact }';

% Selects only the real artifact types.
artindex           = structfun ( @(x) isfield ( x, 'artifact' ), cfg.artfctdef );
artlabel           = artlabel ( artindex );
artifact           = artifact ( artindex );

% Checks the number of artifact types.
if numel ( artlabel ) > 9
  error ( 'This program only supports up to 9 artifacts types.' )
end

% Creates a virtual data containing the artifacts.
artdata            = [];
artdata.label      = artlabel;
artdata.trial {1}  = art2vec ( artifact, datasamples );
artdata.time  {1}  = ( 0: datasamples - 1 ) / hdr.Fs;
artdata.fsample    = hdr.Fs;
artdata.sampleinfo = [ 1 datasamples ];


% Gets the diferent types of events.
eventtypes = unique ( { event.type } );





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up default functions to be available in the right-click menu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% cfg.selfun - labels that are presented in rightclick menu, and is appended using ft_getuserfun(..., 'browse') later on to create a function handle
% cfg.selcfg - cfgs for functions to be executed
defselfun = {};
defselcfg = {};


% add defselfuns to user-specified defselfuns
if ~iscell(cfg.selfun) && ~isempty(cfg.selfun)
  cfg.selfun = {cfg.selfun};
  cfg.selfun = [cfg.selfun defselfun];
  % do the same for the cfgs
  cfg.selcfg = {cfg.selcfg}; % assume the cfg is not a cell-array
  cfg.selcfg = [cfg.selcfg defselcfg];
else
  % simplefft
  defselcfg{1} = [];
  defselcfg{1}.chancolors = chancolors;
  defselfun{1} = 'simpleFFT';
  % multiplotER
  defselcfg{2} = [];
  defselcfg{2}.layout = cfg.layout;
  defselfun{2} = 'multiplotER';
  % topoplotER
  defselcfg{3} = [];
  defselcfg{3}.layout = cfg.layout;
  defselfun{3} = 'topoplotER';
  % topoplotVAR
  defselcfg{4} = [];
  defselcfg{4}.layout = cfg.layout;
  defselfun{4} = 'topoplotVAR';
  % movieplotER
  defselcfg{5} = [];
  defselcfg{5}.layout      = cfg.layout;
  defselcfg{5}.interactive = 'yes';
  defselfun{5} = 'movieplotER';
  % audiovideo
  defselcfg{6} = [];
  defselcfg{6}.audiofile = ft_getopt(cfg, 'audiofile');
  defselcfg{6}.videofile = ft_getopt(cfg, 'videofile');
  defselcfg{6}.anonimize = ft_getopt(cfg, 'anonimize');
  defselfun{6} = 'audiovideo';

  cfg.selfun = defselfun;
  cfg.selcfg = defselcfg;
end


% Stores the data inside the figure.
opt             = [];
opt.hdr         = hdr;
opt.fsample     = hdr.Fs;
opt.senstype    = senstype;
opt.chantype    = chantype;
opt.chancolors  = chancolors;
opt.orgdata     = data;
opt.viewmode    = viewmode;
opt.trlorg      = trlorg;
opt.trlvis      = trlorg;
opt.trlop       = 1;
opt.trllock     = [];
opt.event       = event;
opt.eventtypes  = eventtypes;
opt.eventcolors = [0 0 0; 1 0 0; 0 0 1; 0 1 0; 1 0 1; 0.5 0.5 0.5; 0 1 1; 1 1 0];
opt.eventlabels = {'black', 'red', 'blue', 'green', 'cyan', 'grey', 'light blue', 'yellow'};
opt.artdata     = artdata;
opt.badchan     = cfg.badchan;
opt.projinfo    = cfg.projinfo;
opt.ftsel       = find ( strcmp ( artlabel,cfg.selectfeature ) );
opt.artcolors   = [ 0.9686 0.7608 0.7686; 0.7529 0.7098 0.9647; 0.7373 0.9725 0.6824;0.8118 0.8118 0.8118; 0.9725 0.6745 0.4784; 0.9765 0.9176 0.5686; 0.6863 1 1; 1 0.6863 1; 0 1 0.6000 ];
opt.output      = nargout > 0;

% Activates the projectors.
for pindex = 1: numel ( opt.projinfo )
    opt.projinfo ( pindex ).active = true;
end

% save original layout when viewmode = component
if strcmp(cfg.viewmode, 'component')
  opt.layorg    = cfg.layout;
end

% determine labelling of channels
if strcmp(cfg.plotlabels, 'yes')
  opt.plotLabelFlag = 1;
elseif strcmp(cfg.plotlabels, 'some')
  opt.plotLabelFlag = 2;
else
  opt.plotLabelFlag = 0;
end




% Generates the figure name from the input information.
if nargin < 2
    if isfield ( cfg, 'dataset' )
        dataname = cfg.dataset;
    elseif isfield ( cfg, 'datafile' )
        dataname = cfg.datafile;
    else
        dataname = [];
    end
else
    dataname = inputname (2);
end


% Creates the figure.
h = figure;

set ( h, 'Renderer',              cfg.renderer );
set ( h, 'NumberTitle',           'off' );
set ( h, 'Name',                  sprintf ( '%d: Data browser: %s', double ( h ), dataname ) );

set ( h, 'DefaultUIcontrolUnits', 'normalized' )
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set ( h, 'WindowButtonDownFcn',   { @ft_select_range, 'multiple', false, 'xrange', true, 'yrange', false, 'clear', true, 'contextmenu', cfg.selfun, 'callback', { @select_range_cb, h }, 'event', 'WindowButtonDownFcn'   } )
% set ( h, 'WindowButtonUpFcn',     { @ft_select_range, 'multiple', false, 'xrange', true, 'yrange', false, 'clear', true, 'contextmenu', cfg.selfun, 'callback', { @select_range_cb, h }, 'event', 'WindowButtonUpFcn'     } )
% set ( h, 'WindowButtonMotionFcn', { @ft_select_range, 'multiple', false, 'xrange', true, 'yrange', false, 'clear', true, 'contextmenu', cfg.selfun, 'callback', { @select_range_cb, h }, 'event', 'WindowButtonMotionFcn' } )
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
set ( h, 'WindowButtonDownFcn',   @mouse_cb )
set ( h, 'WindowButtonUpFcn',     @mouse_cb )
set ( h, 'WindowButtonMotionFcn', @mouse_cb )
set ( h, 'KeyPressFcn',           @keyboard_cb )
set ( h, 'CloseRequestFcn',       @cleanup_cb )

% Creates the interface elements.
uicontrol ( h, 'Tag', 'uibottom1', 'Style', 'pushbutton',   'String', opt.viewmode, 'UserData', 't' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '<',          'UserData', 'leftarrow' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '>',          'UserData', 'rightarrow' )

uicontrol ( h, 'Tag', 'uibottom1', 'Style', 'pushbutton',   'String', datatype,     'UserData', 'c' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '<',          'UserData', 'uparrow' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '>',          'UserData', 'downarrow' )

uicontrol ( h, 'Tag', 'uibottom1', 'Style', 'pushbutton',   'String', 'horizontal', 'UserData', 'h' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '-',          'UserData', 'shift+leftarrow' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '+',          'UserData', 'shift+rightarrow' )

uicontrol ( h, 'Tag', 'uibottom1', 'Style', 'pushbutton',   'String', 'vertical',   'UserData', 'v' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '-',          'UserData', 'shift+downarrow' )
uicontrol ( h, 'Tag', 'uibottom2', 'Style', 'pushbutton',   'String', '+',          'UserData', 'shift+uparrow' )

% Creates the artifacts buttons.
for aindex = 1: numel ( artlabel )
    basepos = [ 0.96, 0.90 - ( aindex - 1 ) * 0.08, 0.08, 0.04 ];
    uicontrol ( h, 'Tag', 'uiartif1',  'Style', 'togglebutton', 'String', artlabel { aindex }, 'UserData', sprintf ( '%i',         aindex ), 'Position', basepos - [ 0.05 0.00 0.00 0.00 ], 'BackgroundColor', opt.artcolors ( aindex, : ) )
    uicontrol ( h, 'Tag', 'uiartif2',  'Style', 'pushbutton',   'String', '<',                 'UserData', sprintf ( 'shift+%i',   aindex ), 'Position', basepos - [ 0.05 0.04 0.05 0.00 ], 'BackgroundColor', opt.artcolors ( aindex, : ) )
    uicontrol ( h, 'Tag', 'uiartif2',  'Style', 'pushbutton',   'String', '>',                 'UserData', sprintf ( 'control+%i', aindex ), 'Position', basepos - [ 0.00 0.04 0.05 0.00 ], 'BackgroundColor', opt.artcolors ( aindex, : ) )
end

if strcmp(cfg.viewmode, 'butterfly')
    % button to find label of nearest channel to datapoint
    uicontrol ( h, 'Tag', 'uiright',   'Style', 'togglebutton', 'String', 'identify',          'UserData', 'i' )
end

% Creates the 'edit preproc' button.
uicontrol ( h, 'Tag', 'uiright',    'Style', 'pushbutton',   'String', 'preproc cfg',       'UserData', 'x' )
uicontrol ( h, 'Tag', 'uiselmode',  'Style', 'pushbutton',   'String', 'mode',              'UserData', 's' )
uicontrol ( h, 'Tag', 'uitogproj',  'Style', 'togglebutton', 'String', 'Apply projectors',  'UserData', 'p' )
uicontrol ( h, 'Tag', 'uitogevent', 'Style', 'togglebutton', 'String', 'Show events',       'UserData', 'e' )

ft_uilayout ( h, 'Tag', 'uibottom1',  'width', 0.10, 'height', 0.05, 'retag', 'uibottom' )
ft_uilayout ( h, 'Tag', 'uibottom2',  'width', 0.05, 'height', 0.05, 'retag', 'uibottom' )
ft_uilayout ( h, 'Tag', 'uiright',    'width', 0.08, 'height', 0.05 )
ft_uilayout ( h, 'Tag', 'uiselmode',  'width', 0.08, 'height', 0.05 )
ft_uilayout ( h, 'Tag', 'uitogproj',  'width', 0.08, 'height', 0.05, 'Value', cfg.applyprojector )
ft_uilayout ( h, 'Tag', 'uitogevent', 'width', 0.08, 'height', 0.05, 'Value', cfg.showevent )
ft_uilayout ( h, 'Tag', 'uiartif1',   'width', 0.08, 'height', 0.04, 'retag', 'uiartif' )
ft_uilayout ( h, 'Tag', 'uiartif2',   'width', 0.03, 'height', 0.04, 'retag', 'uiartif' )

ft_uilayout ( h, 'Tag', 'uibottom',   'Callback', @keyboard_cb, 'BackgroundColor', [0.8 0.8 0.8], 'hpos', 'auto', 'vpos', 0.00 );
ft_uilayout ( h, 'Tag', 'uiright',    'Callback', @keyboard_cb, 'BackgroundColor', [0.8 0.8 0.8], 'hpos', 0.91, 'vpos', 'auto', 'vshift', -0.10 - aindex * 0.08 );
ft_uilayout ( h, 'Tag', 'uiselmode',  'Callback', @keyboard_cb, 'BackgroundColor', [0.8 0.8 0.8], 'hpos', 0.91, 'vpos', 'auto', 'vshift', -0.22 - aindex * 0.08 );
ft_uilayout ( h, 'Tag', 'uitogproj',  'Callback', @keyboard_cb, 'KeyPressFcn', @keyboard_cb, 'BackgroundColor', [0.8 0.8 0.8], 'hpos', 0.91, 'vpos', 'auto', 'vshift', -0.28 - aindex * 0.08 );
ft_uilayout ( h, 'Tag', 'uitogevent', 'Callback', @keyboard_cb, 'BackgroundColor', [0.8 0.8 0.8], 'hpos', 0.91, 'vpos', 'auto', 'vshift', -0.34 - aindex * 0.08 );
ft_uilayout ( h, 'Tag', 'uiartif',    'Callback', @keyboard_cb );

if numel ( opt.projinfo ) == 0
    cfg.applyprojector = false;
    set ( findobj ( h, 'Tag', 'uitogproj' ), 'Value', false, 'Enable', 'off' )
end


% Creates the axes.
axes ( 'Tag', 'chaninfo', 'Position', [ 0.000 0.110 0.130 0.815 ], 'NextPlot', 'add', 'YLim', [ 0 1 ], 'XTick', [], 'YTick', [], 'Visible', 'off', 'PickableParts', 'none' );
axes ( 'Tag', 'chandata', 'Position', [ 0.130 0.110 0.775 0.815 ], 'NextPlot', 'add', 'YLim', [ 0 1 ], 'XTick', [], 'YTick', [], 'Color', cfg.bgcolor );

% Enables the custom text for the data cursor.
dcm = datacursormode ( h );
set ( dcm, 'UpdateFcn', @datacursortext );


% Writes out the first segment.
setappdata ( h, 'opt', opt );
setappdata ( h, 'cfg', cfg );
definetrial_cb ( h );
redraw_cb ( h );

% %% Scrollbar
%
% % set initial scrollbar value
% dx = maxtime;
%
% % set scrollbar position
% fig_pos=get(gca, 'position');
% scroll_pos=[fig_pos(1) fig_pos(2) fig_pos(3) 0.02];
%
% % define callback
% S=['set(gca, ''xlim'',get(gcbo, ''value'')+[ ' num2str(mintime) ', ' num2str(maxtime) '])'];
%
% % Creating Uicontrol
% s=uicontrol('style', 'slider',...
%     'units', 'normalized', 'position',scroll_pos,...
%     'callback',S, 'min',0, 'max',0, ...
%     'visible', 'off'); %'value', xmin

% set initial scrollbar value
% dx = maxtime;
%
% % set scrollbar position
% fig_pos=get(gca, 'position');
% scroll_pos=[fig_pos(1) fig_pos(2) fig_pos(3) 0.02];
%
% % define callback
% S=['set(gca, ''xlim'',get(gcbo, ''value'')+[ ' num2str(mintime) ', ' num2str(maxtime) '])'];
%
% % Creating Uicontrol
% s=uicontrol('style', 'slider',...
%     'units', 'normalized', 'position',scroll_pos,...
%     'callback',S, 'min',0, 'max',0, ...
%     'visible', 'off'); %'value', xmin
%initialize postion of plot
% set(gca, 'xlim', [xmin xmin+dx]);


% Maximizes the figure, if possible.
if isprop ( gcf, 'WindowState' )
  set ( gcf, 'WindowState', 'maximized' )
end


if opt.output
    
    % Lists the original artifacts of each type.
    if numel ( artlabel )
        fprintf ( 1, 'The original data has:\n' );
        for tindex = 1: numel ( artlabel )
            fprintf ( 1, '  %3i artifacts of type ''%s''.\n', size ( artifact { tindex }, 1 ), artlabel { tindex } );
        end
    end
    
    % Waits fort he user to close the GUI.
    uiwait ( h );
    
    % Gets the variables and the configuration.
    opt    = getappdata ( h, 'opt' );
    guicfg = getappdata ( h, 'cfg' );
    
    % Deletes the GUI.
    delete ( h );
    
    
    % Converts the artifact vectors to artifacts.
    artifact = vec2art ( opt.artdata.trial {1} );
    
    % Stores the modified artifacts in the output.
    for tindex = 1: numel ( opt.artdata.label )
        cfg.artfctdef.( opt.artdata.label { tindex} ).artifact = artifact { tindex };
    end
    
    
    % Lists the current artifacts of each type.
    if numel ( artlabel )
        fprintf ( 1, 'The reviewed data has:\n' );
        for tindex = 1: numel ( artlabel )
            fprintf ( 1, '  %3i artifacts of type ''%s''.\n', size ( artifact { tindex }, 1 ), artlabel { tindex } );
        end
    end
    
    % Adds the update event to the output cfg
    cfg.event = opt.event;
    
    % Adds the update bad channels to the output cfg
    cfg.badchan = opt.badchan;
    
    % Adds the preproc info to the output, if any.
    if isfield ( guicfg, 'preproc' )
        cfg.preproc = guicfg.preproc;
    end
else
    clear cfg
end
end







function mouse_cb ( h, eventdata )

% Gets the configuration from the figure.
cfg = getappdata ( h, 'cfg' );


% Gets the primary and secondary axes.
ax1 = findall ( h, 'Tag', 'chandata' );
ax2 = findall ( h, 'Tag', 'chaninfo' );

% Gets the mouse position respect to the main or secondary axes.
cursor1 = get_cursor ( ax1, true );
cursor2 = get_cursor ( ax2, true );

% If the mouse is over the secondary axes, shows the event labels.
if cfg.showevent
    if ~isnan ( cursor2 (2) )
        set ( findobj ( h, 'Tag', 'event' ), 'Visible', 'on' );
    else
        set ( findobj ( h, 'Tag', 'event' ), 'Visible', 'off' );
    end
end

% % Gets the position of the "Toggle event" button, in pixels.
% bev = findall ( h, 'Tag', 'uitogevent' );
% pev = getpixelposition ( bev );
% 
% % Gets the cursor position.
% pc  = get ( h, 'CurrentPoint' );
% 
% % Checks if the cursor is inside the button.
% if pc (1) >= pev (1) && pc (1) <= pev (1) + pev (3) && pc (2) >= pev (2) && pc (2) <= pev (2) + pev (4)
%     set ( findobj ( h, 'tag', 'eventlabel' ), 'Visible', 'on' );
% else
%     set ( findobj ( h, 'tag', 'eventlabel' ), 'Visible', 'off' );
% end




% Finds out if the mouse is being pressed.
userData  = getappdata ( h, 'select_range_m' );
selecting = ~isempty ( userData ) && numel ( userData.range ) > 0 && any ( isnan ( userData.range ( end, : ) ) );

% If the cursor is not in either axes, exits.
if isnan ( cursor1 (2) ) && isnan ( cursor2 (2) ) && ~selecting
    return
end


% Checks if the selection mode is "channel".
if strcmp ( cfg.selectmode, 'markbadchannel' )
    
    % Gets the functioning mode.
    switch eventdata.EventName
        case 'WindowMousePress'
            toggle_bad ( h )
        otherwise
            return
    end
    
% Othewise uses FieldTrip behavior.
else
    
    % Gets the functioning mode.
    switch eventdata.EventName
        case 'WindowMouseMotion'
            mode = 'WindowButtonMotionFcn';
        case 'WindowMousePress'
            mode = 'WindowButtonDownFcn';
        case 'WindowMouseRelease'
            mode = 'WindowButtonUpFcn';
        otherwise
            return
    end
    
    % Calls FieldTrip function.
    ft_select_range ( h, eventdata, 'multiple', false, 'xrange', true, 'yrange', false, 'clear', true, 'contextmenu', cfg.selfun, 'callback', { @select_range_cb, h }, 'event', mode )
end
end



% Function to toggle the back channel state.
function toggle_bad ( h )

% Gets the data from the figure.
opt = getappdata ( h, 'opt' );


% Gets the primary and secondary axes.
ax1 = findall ( h, 'Tag', 'chandata' );
ax2 = findall ( h, 'Tag', 'chaninfo' );

% Gets the mouse position respect to the main or secondary axes.
cursor = get_cursor ( ax1, true );
if isnan ( cursor (2) )
    cursor = get_cursor ( ax2, true );
end

% If not in either axes, exits.
if isnan ( cursor (2) )
    return
end


% Gets the number of channels currently at display.
nchan = numel ( opt.oldchan );

% Gets the selected channel.
schan = nchan - floor ( nchan * cursor (2) + eps );
schan = opt.channel ( schan );

% Toggles the state of the selected channel.
if ismember ( schan, opt.badchan )
    opt.badchan = setdiff ( opt.badchan, schan );
else
    opt.badchan = union ( opt.badchan, schan );
end

% Updates the data in the figure.
setappdata ( h, 'opt', opt );


% Re-draws the data.
redraw_label ( h )
redraw_chan ( h )

end



function cursor = get_cursor ( hObject, check )

% Gets the mouse position respect to the main axes.
cursor = get ( hObject, 'CurrentPoint' );
cursor = cursor ( 1, 1: 2 );

% Checks if the cursor is inside the main axes, if requested.
if nargin > 1 && check
    
    % Gets the definition of the area currently shown in the main axes.
    axarea = axis ( hObject );
    
    % If the cursor is outside of the main axis, sets it to NaN.
    if any ( cursor < axarea ( [ 1 3 ] ) ) || any ( cursor > axarea ( [ 2 4 ] ) )
        cursor = nan ( 1, 2 );
    end
end
end




function toggle_proj ( h, ~ )


% Gets the focus back to the figure, if required.
if ~strcmp ( get ( h, 'Type' ), 'figure' )
    set ( h, 'Enable', 'off' );
    drawnow update
    set ( h, 'Enable', 'on' );
end

% Gets the data from the figure.
h   = ancestor   ( h, 'figure' );




% Toggles the projects on/off.
cfg = getappdata ( h, 'cfg' );
cfg.applyprojector = ~cfg.applyprojector;
setappdata ( h, 'cfg', cfg );

% Changes the state of the toggle button.
set ( findobj ( h, 'Tag', 'uitogproj' ), 'Value', cfg.applyprojector )

% Re-draws the data with the new configuration.
redraw_chan ( h )

end


function toggle_event ( h )

% Toggles the events on/off.
cfg = getappdata ( h, 'cfg' );
cfg.showevent = ~cfg.showevent;
setappdata ( h, 'cfg', cfg );

% Changes the state of the toggle button.
set ( findobj ( h, 'Tag', 'uitogevent' ), 'Value', cfg.showevent )

% Re-draws the data with the new configuration.
redraw_event ( h )

end


function toggle_mode ( h )

% Toggles between selection modes.
cfg = getappdata ( h, 'cfg' );

switch cfg.selectmode
    case 'markartifact'
        cfg.selectmode = 'markbadchannel';%'markpeakevent';
    case 'markpeakevent'
        cfg.selectmode = 'marktroughevent';
    case 'marktroughevent'
        cfg.selectmode = 'markbadchannel';
    case 'markbadchannel'
        cfg.selectmode = 'markartifact';
    otherwise
        return
end

setappdata ( h, 'cfg', cfg );

fprintf ( 'Switching to selection mode ''%s''.\n', cfg.selectmode );

% Updates the label in the button.
update_mode ( h )

end


function update_mode ( h )

cfg = getappdata ( h, 'cfg' );

switch cfg.selectmode
    case 'markartifact'
        ft_uilayout ( h, 'Tag', 'uiselmode', 'string', 'Mode artifact' )
    case 'markpeakevent'
        ft_uilayout ( h, 'Tag', 'uiselmode', 'string', 'Mode event' )
    case 'marktroughevent'
        ft_uilayout ( h, 'Tag', 'uiselmode', 'string', 'Mode through' )
    case 'markbadchannel'
        ft_uilayout ( h, 'Tag', 'uiselmode', 'string', 'Mode channel' )
        
        % Deletes the current selection box, if any.
        userData = getappdata ( h, 'select_range_m');
        if ~isempty ( userData )
            delete ( userData.box ( ishandle ( userData.box ) ) );
            userData.range = [];
            userData.box   = [];
            setappdata (h, 'select_range_m', userData );
        end
    otherwise
        return
end
end









function definetrial_cb ( h, eventdata ) %#ok<INUSD>

opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Forces the regeneration of artifacts and events.
opt.oldtime = [];

switch cfg.continuous
    case 'no'
        
        % When zooming in the trial is locked.
        if isempty ( opt.trllock )
            opt.trllock = opt.trlop;
        end
        
        % Gets the length of the current trial, in seconds.
        locktrllen = ( diff ( opt.trlorg ( opt.trllock, [ 1 2 ] ) ) + 1 ) / opt.fsample;
        
        % If the trial is almost complete shows it complete.
        if abs ( locktrllen - cfg.blocksize ) / locktrllen < 0.1
            cfg.blocksize = locktrllen;
        end
        
        % Calculates the block size in samples.
        blocklen    = round ( opt.fsample * cfg.blocksize );
        
        
        % Shows a portion of the trial.
        if cfg.blocksize < locktrllen
            
            % Updates the trial visualization type.
            opt.viewmode = 'trialsegment';
            
            % Locks the trial if needed.
            if isempty ( opt.trllock )
                opt.trllock = opt.trlop;
            end
            
            % Gets the current position.
            segpos  = mean ( opt.trlvis ( opt.trlop, 1 ) );
            
            % Calculates the segments' edges.
            segbegs = opt.trlorg ( opt.trllock, 1 ): blocklen: opt.trlorg ( opt.trllock, 2 );
            
            % Constructs the trial definition.
            opt.trlvis = cat ( 2, segbegs', segbegs' + blocklen - 1, segbegs' - segbegs (1) );
            opt.trlvis ( end, 2 ) = opt.trlorg ( opt.trllock, 2 );
            
            % Goes to the segment nearest to the current position.
            opt.trlop   = nearest ( segbegs, segpos );
            
        % Shows the whole trial plus some padding.
        elseif cfg.blocksize >= locktrllen
            
            % Updates the trial visualization type.
            opt.viewmode = 'trial';
            
            % Unlocks the trial, if needed.
            if ~isempty ( opt.trllock )
                opt.trlop   = opt.trllock;
                opt.trllock = [];
            end
            
            % Sets the viasualization segments as the trials.
            opt.trlvis  = opt.trlorg;
        end
        
        % Updates the button label.
        set ( findobj ( h, 'string', 'trial' ), 'string', opt.viewmode );
        set ( findobj ( h, 'string', 'trialsegment' ), 'string', opt.viewmode );
        
    otherwise
        
        % Calculates the block size in samples.
        blocklen    = round ( opt.fsample * cfg.blocksize );
        
        % Gets the current position.
        segpos  = mean ( opt.trlvis ( opt.trlop, 1 ) );
        
        % Calculates the segments' edges.
        segbegs = min ( opt.trlorg ( :, 1 ) ): blocklen: max ( opt.trlorg ( :, 2 ) );
        
        % Constructs the trial definition.
        opt.trlvis = cat ( 2, segbegs', segbegs' + blocklen - 1, segbegs' - segbegs (1) );
        opt.trlvis ( end, 2 ) = max ( opt.trlorg ( :, 2 ) );
        
        % Goes to the segment nearest to the current position.
        opt.trlop   = nearest ( segbegs, segpos );
        
        % if size(opt.trlorg,1)==1
        %     offset = begsamples - repmat(begsamples(1), [1 numel(begsamples)]); % offset for all segments compared to the first
        %     offset = offset + opt.trlorg(1,3);
        %     trlvis(:,3) = offset;
        % else
        %     offset = begsamples - repmat(begsamples(1), [1 numel(begsamples)]);
        %     trlvis(:,3) = offset;
        % end
end

setappdata ( h, 'opt', opt );
setappdata ( h, 'cfg', cfg );
end


function preproc_cfg1_cb ( h, eventdata ) %#ok<INUSD>

h   = ancestor   ( h, 'figure' );
cfg = getappdata ( h, 'cfg' );


% Creates the banner.
banner = {
    '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%'
    '% Add or change options for on-the-fly preprocessing'
    '% Use as cfg.preproc.option=value'
    '%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%' };

% Parses the preprocessing options.
if ~isempty ( cfg.preproc )
    code = printstruct ( 'cfg.preproc', cfg.preproc );
else
    code = '';
end

% Adds the banner.
code = cat ( 1, banner, code );

% Saves the information.
opt.parent  = h;

% Creates the dialog window.
dlg = dialog ( 'Name', 'cfg.preproc editor', 'WindowStyle', 'normal', 'HandleVisibility', 'callback' );
opt.savebutton = uicontrol ( dlg, 'Style', 'pushbutton', 'Units', 'normalized', 'Position', [ 0.81 0.60 0.18 0.10 ], 'String', 'Save and close', 'Callback', @preproc_cfg2_cb );
opt.codebox    = uicontrol ( dlg, 'Style', 'edit',       'Units', 'normalized', 'Position', [ 0.00 0.00 0.80 1.00 ], 'string', code, 'Units', 'normalized', 'backgroundColor', [ 1 1 1 ], 'HorizontalAlign', 'left', 'max', 2, 'min', 0, 'FontName', 'Courier', 'FontUnits', cfg.editfontunits, 'FontSize', cfg.editfontsize );

setappdata ( dlg, 'opt', opt );

end


function preproc_cfg2_cb ( h, eventdata ) %#ok<INUSD>

h   = ancestor   ( h, 'figure' );
opt = getappdata ( h, 'opt' );
cfg = getappdata ( opt.parent, 'cfg' );

% Removes ampty lines and coments.
code = get ( opt.codebox, 'string' );
rem  = cellfun ( @(x) strncmp ( x, '%', 1 ) || isempty ( x ), strtrim ( code ) );
code ( rem ) = [];

% If no code does nothing.
if isempty ( code )
    delete ( h )
    return
end

% Checks that all the lines start by 'cfg.preproc'.
if ~all ( strncmp ( code, 'cfg.preproc.', 12 ) )
    errordlg ( 'Preprocessing options must be specified as ''cfg.preproc.xxx''.', 'cfg.preproc editor', 'modal' )
end

% Removes the old preprocessing options.
cfg.preproc = [];

% Appends ';' to the lines to suppress output and evaluates.
code = strcat ( code, ';' );
cellfun ( @eval, code );

setappdata ( opt.parent, 'cfg', cfg )
delete ( h )
redraw_cb ( opt.parent )
end


function data = scale_data ( h, data, channel )

% Gets the information.
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );


% % Gets the data.
% channel = opt.curdata.label;
% data    = opt.curdata.trial {1};

% Applies the selected scales to all the channel types.
if ~isempty ( cfg.eegscale )
    chansel = ismember ( channel, opt.chantype.eeg );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.eegscale;
end
if ~isempty ( cfg.eogscale )
    chansel = ismember ( channel, opt.chantype.eog );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.eogscale;
end
if ~isempty ( cfg.ecgscale )
    chansel = ismember ( channel, opt.chantype.ecg );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.ecgscale;
end
if ~isempty ( cfg.emgscale )
    chansel = ismember ( channel, opt.chantype.emg );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.emgscale;
end
if ~isempty ( cfg.megscale )
    chansel = ismember ( channel, opt.chantype.meg );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.megscale;
end
if ~isempty ( cfg.magscale )
    chansel = ismember ( channel, opt.chantype.megmag );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.magscale;
end
if ~isempty ( cfg.gradscale )
    chansel = ismember ( channel, opt.chantype.meggrad );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.gradscale;
end
if ~isempty ( cfg.chanscale )
    chansel = ismember ( channel, ft_channelselection ( cfg.channel, channel ) ) ;
    data ( chansel, : ) = data ( chansel, : ) .* repmat ( cfg.chanscale, 1, size ( data, 2 ) );
end
if ~isempty ( cfg.mychanscale )
    chansel = ismember ( channel, ft_channelselection ( cfg.mychan, channel ) );
    data ( chansel, : ) = data ( chansel, : ) .* cfg.mychanscale;
end
end


function select_range_cb ( h, range, cmenulab )

opt       = getappdata(h, 'opt');
cfg       = getappdata(h, 'cfg');

% Gets the sample information for the current trial.
begsample = opt.trlvis ( opt.trlop, 1 );
endsample = opt.trlvis ( opt.trlop, 2 );
offset    = opt.trlvis ( opt.trlop, 3 );

% Converts the range to samples.
begsel    = round ( range (1) * opt.fsample + begsample - offset - 1 );
endsel    = round ( range (2) * opt.fsample + begsample - offset );

% Makes sure that the selection is within the trial.
begsel    = max ( begsample, begsel );
endsel    = min ( endsample, endsel );

% mark or execute selfun
if isempty ( cmenulab )
    
    % Adds or removes artifacts.
    if strcmp ( cfg.selectmode, 'markartifact' )
        
        % Gets the old artifact vector.
        oldart = opt.artdata.trial {1} ( opt.ftsel, : );
        
        % Constructs the new artifact vector.
        newart = false ( 1, opt.artdata.sampleinfo (2) );
        newart ( begsel: endsel ) = true;
        
        % Removes the overlapping artifacts or adds a new artifact.
        if any ( oldart & newart )
            artifact = oldart & ~newart;
        else
            artifact = oldart | newart;
        end
        
        % Stores the new artifact definition.
        opt.artdata.trial {1} ( opt.ftsel, : ) = artifact;
        
        % Redraws the artifacts.
        setappdata ( h, 'opt', opt );
        redraw_art ( h );
        
    % Adds or removes events.
    elseif ismember ( cfg.selectmode, { 'markpeakevent' 'marktroughevent' } )
        
        % Looks for events in the selected area.
        eventsel = [ opt.event.sample ] >= begsel & [ opt.event.sample ] <= endsel;
        
        % Removes the overlapping events or adds a new event.
        if any ( eventsel )
            opt.event ( eventsel ) = [];
        else
            
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % Gets the position of either the peak or the valley.
            if strcmp ( cfg.selectmode, 'markpeakevent' )
                [ ~, index ] = max ( opt.curdata.trial {1} ( begsel - begsample + 1: endsel - begsample + 1 ) );
                val = 'peak';
            else
                [ ~, index ] = min ( opt.curdata.trial {1} ( begsel - begsample + 1: endsel - begsample + 1 ) );
                val = 'trough';
            end
            
            % Generates a new event.
            event          = [];
            event.type     = 'Manual';
            event.sample   = begsel + index - 1;
            event.value    = val;
            event.offset   = 0;
            event.duration = 1;
            
            % Adds the event to the event list and sorts the events.
            opt.event ( end + 1) = event;
            [ ~, index ] = sort ( [ opt.event.sample ] );
            opt.event = opt.event ( index );
        end
        
        % Redraws the events.
        setappdata ( h, 'opt', opt );
        redraw_event ( h );
    end
else
    
    % Gets the data.
    switch cfg.seldat
        case 'current'
            dummy = opt.curdata;
        case 'all'
            dummy = opt.orgdata;
    end
    
    % Generates a data structure with the selected data.
    seldata            = keepfields ( dummy, { 'hdr', 'label', 'grad', 'elec', 'fsample' } );
    seldata.trial {1}  = ft_fetch_data ( dummy, 'begsample', begsel, 'endsample', endsel );
    seldata.time  {1}  = ( offset + begsel - begsample + ( 0: endsel - begsel ) ) / dummy.fsample;
    
    % get windowname and give as input (can be used for the other functions as well, not implemented yet)
    if ~strcmp ( opt.viewmode, 'trialsegment' )
        wtitle = sprintf ( '%s %d/%d. Time from %g to %g s', opt.viewmode, opt.trlop, size(opt.trlvis,1), seldata.time{1}(1), seldata.time{1}(end));
    else
        wtitle = sprintf ( 'Trial %d/%d. Segment: %d/%d. Time from %g to %g s', opt.trllock, size(opt.trlorg,1), opt.trlop, size(opt.trlvis,1), seldata.time{1}(1), seldata.time{1}(end));
    end
    
    % Gets the configuration for the function.
    selfunind = strcmp ( cfg.selfun, cmenulab );
    funcfg    = cfg.selcfg { selfunind };
    funcfg.figurename = sprintf ( '%s: %s', cmenulab, wtitle );
    
    % Evaluates the function.
    funhandle = ft_getuserfun ( cmenulab, 'browse' );
    funhandle ( funcfg, seldata );
end
end


function redraw_cb ( h, eventdata ) %#ok<INUSD>

h   = ancestor   ( h, 'figure' );
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Brings the figure to the front.
figure ( h );

% Updates the selection mode.
update_mode ( h )


% Adds the physiological channels (cfg.physio) at the end.
opt.channel = union ( cfg.channel, opt.hdr.label ( cfg.physio ), 'stable' );

% Checks if the list of showed channels have changed.
samechan = isfield ( opt, 'oldchan' ) && isequal ( opt.oldchan, opt.channel );
opt.oldchan = opt.channel;

% Checks if the showed time span have changed.
sametime = isfield ( opt, 'oldtime' ) && isequal ( opt.oldtime, opt.trlvis ( opt.trlop ) );
opt.oldtime = opt.trlvis ( opt.trlop );
opt.orgdata.sampleinfo = single ( opt.orgdata.sampleinfo );

% Gets the current data, if required.
if ~sametime
    
    begsample = single ( opt.trlvis ( opt.trlop, 1 ) );
    endsample = single ( opt.trlvis ( opt.trlop, 2 ) );
    offset    = single ( opt.trlvis ( opt.trlop, 3 ) );
    
    if isempty ( opt.orgdata )
        data = ft_read_data  ( cfg.datafile, 'header', opt.hdr, 'begsample', begsample, 'endsample', endsample, 'checkboundary', strcmp ( cfg.continuous, 'no' ), 'dataformat', cfg.dataformat, 'headerformat', cfg.headerformat );
    else
        data = ft_fetch_data ( opt.orgdata,  'header', opt.hdr, 'begsample', begsample, 'endsample', endsample, 'allowoverlap', true );
    end
    
    if ~isempty ( cfg.precision )
        data = cast ( data, cfg.precision );
    end
    
    % Calculates the data's time vector.
    time = ( offset + ( 0: size ( data, 2 ) -1 ) ) / single ( opt.fsample );
    
    % Preprocess the data and gets the time axis.
    [ data, label, time ] = preproc ( data, opt.hdr.label, time, cfg.preproc );
    
    % Gets the sampling frequency, if modified by preproc.
    fsample = 1 / diff ( time ( [ 1 2 ] ) );
    
    % Padds the data with NaN if not enough samples.
    if round ( single ( cfg.blocksize ) * fsample ) > size ( data, 2 )
        data = cat ( 2, data, nan ( numel ( label ), round ( cfg.blocksize * fsample ) - size ( data, 2 ) ) );
        time = time (1) + ( 0: size ( data, 2 ) - 1 ) / fsample;
    end
    
    % Creates a FieldTrip data structure.
    opt.curdata.hdr        = opt.hdr;
    opt.curdata.label      = label;
    opt.curdata.time  {1}  = time;
    opt.curdata.trial {1}  = data;
    opt.curdata.fsample    = fsample;
end


% Stores the current data in the GUI.
setappdata ( h, 'opt', opt );
setappdata ( h, 'cfg', cfg );

% Draws the artifacts and events if needed.
if ~sametime
    redraw_art ( h )
    redraw_event ( h )
end

% Draws the time series.
redraw_chan ( h )

% Draws the channel labels and the topographies if needed.
if ~samechan
    redraw_label ( h )
    redraw_topo ( h )
end

drawnow
end


function redraw_art ( h )

% Gets the information.
opt = getappdata ( h, 'opt' );

% Selects the channel data axis to draw.
ha = findobj ( h, 'Tag', 'chandata' );

% Removes the old artifacts.
delete ( findobj ( ha, 'Tag', 'artifact' ) );


% Gets the information of the current trial or segment.
begsample  = opt.trlvis ( opt.trlop, 1 );
endsample  = opt.trlvis ( opt.trlop, 2 );
offset     = opt.trlvis ( opt.trlop, 3 );

% Gets the artifacts for the current time span.
artifacts  = ft_fetch_data ( opt.artdata, 'begsample', begsample, 'endsample', endsample );

% Gets the time vector.
time       = ( offset + ( 0: endsample - begsample ) ) / opt.fsample;

% Reorders the artifact sot he current one is drawed last.
tindexes   = 1: size ( artifacts, 1 );
tindexes   = setdiff ( tindexes, opt.ftsel, 'stable' );
tindexes   = cat ( 2, tindexes, opt.ftsel );

% Goes through each artifact type.
for tindex = tindexes
    
    % Gets the current artifact data.
    artifact = artifacts ( tindex, : );
    
    % If no artifact does nothing.
    if ~any ( artifact ), continue, end
    
    % Plots the artifacts.
    area ( ha, time, artifact * 100, 'Tag', 'artifact', 'LineStyle', 'none', 'FaceColor', opt.artcolors ( tindex, : ) )
end

% Brings the events and the time series to the top.
uistack ( findobj ( ha, 'Tag', 'event' ), 'top' )
uistack ( findobj ( ha, 'Tag', 'timecourse' ), 'top' )

% Selects the right toggle button.
set ( findobj ( h, 'Tag', 'uiartif', 'Style', 'togglebutton' ), 'Value', 0 );
set ( findobj ( h, 'Tag', 'uiartif', 'Style', 'togglebutton', 'String', opt.artdata.label { opt.ftsel } ), 'Value', 1 );
end


function redraw_event ( h )

% Gets the information.
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Selects the channel data axis to draw.
ha = findobj ( h, 'Tag', 'chandata' );

% Deletes the previous events.
delete ( findobj ( ha, 'Tag', 'event' ) );
delete ( findobj ( ha, 'Tag', 'eventdim' ) );

% Checks if the events should be plotted.
if ~cfg.showevent
    return
end

% Checks if the events should be plotted in this view mode.
if ~ismember ( cfg.viewmode, { 'butterfly', 'component', 'vertical' } )
    return
end


% Lists the type of events.
eventtypes = unique ( { opt.event.type } );
eventtypes = union ( opt.eventtypes, eventtypes, 'stable' );

% Gets the information of the current trial or segment.
begsample  = opt.trlvis ( opt.trlop, 1 );
endsample  = opt.trlvis ( opt.trlop, 2 );
offset     = round ( opt.curdata.time {1} (1) * opt.fsample );

% Gets the list of events.
event      = opt.event;
eventindex = [ event.sample ] >= begsample &  [ event.sample ] <= endsample;
event      = event( eventindex );

% Gets the current events type and value.
eventtime  = [ event.sample ]' - single ( begsample ) + offset;
eventtime  = eventtime / opt.fsample;
eventtype  = { event.type }';
eventvalue = { event.value }';

% Transforms the values into strings.
eventvalue = cellfun ( @num2str, eventvalue, 'UniformOutput', false );


% Adds the description, if any.
if isfield ( event, 'description' )
    eventdesc  = { event.description }';
    eventvalue = strcat ( eventvalue, { newline }, eventdesc );
end


% Creates the label for each event.
switch cfg.ploteventlabels
    case 'type=value'
        eventlabel = strcat ( eventtype, '=', eventvalue );
        eventcolor = zeros ( numel ( event ), 2 );
    case 'colorvalue'
        eventlabel = eventvalue;
        eventcolor = opt.eventcolors ( my_matchstr ( eventtypes, eventtype ), : );
    otherwise
        eventlabel = cell ( size ( eventtype ) );
        eventcolor = zeros ( numel ( event ), 2 );
end

% Creates a translucid version of the events.
eventcolor2 = eventcolor;
eventcolor2 ( :, 4 ) = 0.2;


% Gets the list of unique time instants.
conctimes = unique ( eventtime );
conctimes ( :, 2 ) = 0;

% Goes through each event.
for eindex = 1: numel ( event )
    
    % Draws the event.
    plot ( ha, eventtime ( [ eindex eindex ] ), [ 0 1 ], 'LineWidth', 0.1, 'Color', eventcolor ( eindex, : ), 'Tag', 'event', 'Visible', 'off' );
    
    % Draws a dimmed version of the event.
    handle = plot ( ha, eventtime ( [ eindex eindex ] ), [ 0 1 ], 'LineWidth', 0.1, 'Color', eventcolor2 ( eindex, : ), 'Tag', 'eventdim' );
    
    % Gets the number of past concurrent events.
    timeindex = conctimes ( :, 1 ) == eventtime ( eindex );
    voffset   = conctimes ( timeindex, 2 ) * 0.06;
    conctimes ( timeindex, 2 ) = conctimes ( timeindex, 2 ) + 1;
    
    % Writes the label.
    text ( double ( eventtime ( eindex ) ), 1 - double ( voffset ), eventlabel { eindex }, 'Parent', ha, 'Tag', 'event', 'Color', eventcolor ( eindex, : ), 'Horizontalalignment', 'left', 'VerticalAlignment', 'top', 'FontUnits', cfg.fontunits, 'FontSize', cfg.fontsize, 'Interpreter', 'none', 'Visible', 'off' );
    
    % Stores the event information in the cursor data.
    cursordata.type       = 'event';
    cursordata.eventtime  = eventtime ( eindex );
    cursordata.eventtype  = event     ( eindex ).type;
    cursordata.eventvalue = event     ( eindex ).value;
    setappdata ( handle, 'cursordata', cursordata );
end

% Brings the time series to the top.
uistack ( findobj ( ha, 'Tag', 'timecourse' ), 'top' )
end


function redraw_chan ( h )

% Gets the information.
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Selects the channel data axis to draw.
ha = findobj ( h, 'Tag', 'chandata' );

% Deletes the old time series.
delete ( findobj ( ha, 'Tag', 'timecourse' ) );
delete ( findobj ( h, 'Tag', 'identify' ) );

% Gets the raw data.
channel = opt.curdata.label;
data    = opt.curdata.trial {1};
time    = opt.curdata.time  {1};


% Applies the projectors, if requested.
if cfg.applyprojector
    
    % Generates the projectors ignoring the bad channels.
%     projector = mne_make_projector ( opt.projinfo, opt.curdata.label, opt.badchan );
    projector = mymne_make_projector ( opt.projinfo, opt.curdata.label, opt.badchan );
    
    % Applies the projectors to the data.
    data    = projector * data;
end


% Gets the list of active channels.
chanindx = my_matchstr ( channel, opt.channel );
badchan  = ismember ( opt.channel, opt.badchan );

% Creates an scalated copy of the data.
plotdata = scale_data ( h, data, channel );

% Selects only the required data.
data     = data ( chanindx, : );
plotdata = plotdata ( chanindx, : );


if strcmp ( cfg.viewmode, 'butterfly' )
    
    % Scales the data to 1.
    plotdata = ( plotdata - sum ( cfg.ylim ) / 2 ) / diff ( cfg.ylim );
    
    % Scales the data to 1/2 and centers it in the right y.
    plotdata = bsxfun ( @plus, plotdata / 2, .5 );
    
    % Gets the colors for the current channels.
    chancolor = opt.chancolors ( chanindx, : );
    
    % Makes the bad channels translucid.
    chancolor (  badchan, 4 ) = 0.2;
    chancolor ( ~badchan, 4 ) = 1.0;
    
%     % Sets the color order for the plot.
%     set ( ha, 'ColorOrder', chancolor, 'ColorOrderIndex', 1 )
    
    % Draws all the channels at once.
    handle = plot ( ha, time, plotdata', 'Tag', 'timecourse' );
    
    
    % Goes through each channel.
    for cindex = 1: numel ( chanindx )
        
        % Stores the channel information in the cursor data.
        cursordata.type  = 'channel';
        cursordata.time  = time;
        cursordata.data  = data ( cindex, : );
        cursordata.label = opt.hdr.label { chanindx ( cindex ) };
        setappdata ( handle ( cindex ), 'cursordata', cursordata );
        
        % Sets the channel color.
        set ( handle ( cindex ), 'Color', chancolor ( cindex, : ) )
    end
    
    
    % Creates eleven ticks for the x axis.
    xTick      = linspace ( time (1), time (end), 11 );
    xTickLabel = cellstr ( num2str ( xTick', '%.2f' ) );
    
    % Creates four ticks for the y axis..
    yTick      = [ -1/2 -1/4 1/4 1/2 ] + .5;
    yTickLabel = [ .0 .25 .75 1 ] .* range ( cfg.ylim ) + cfg.ylim (1);
    
elseif ismember ( cfg.viewmode, { 'component', 'vertical' } )
    
    % Calculates the centers for the channels.
    centers  = fliplr ( ( 0.5: numel ( chanindx ) ) / numel ( chanindx ) );
    
    % Scales the data to 1.
    plotdata = ( plotdata - sum ( cfg.ylim ) / 2 ) / diff ( cfg.ylim );
    
    % Scales the data to 1/channels and centers it in the right y.
    plotdata = bsxfun ( @plus, plotdata / numel ( chanindx ), centers (:) );
    
    % Gets the colors for the current channels.
    chancolor = opt.chancolors ( chanindx, : );
    
%     % Makes the bad channels lighter.
%     chancolor ( badchan, : ) = 1 - ( 1 - chancolor ( badchan, : ) ) / 4;
    
    % Makes the bad channels translucid.
    chancolor (  badchan, 4 ) = 0.2;
    chancolor ( ~badchan, 4 ) = 1.0;
    
%     % Sets the color order for the plot.
%     set ( ha, 'ColorOrder', chancolor, 'ColorOrderIndex', 1 )
    
    % Draws all the channels at once.
    handle = plot ( ha, time, plotdata', 'Tag', 'timecourse' );
    
    % Goes through each channel.
    for cindex = 1: numel ( chanindx )
        
        % Stores the channel information in the cursor data.
        cursordata.type  = 'channel';
        cursordata.time  = time;
        cursordata.data  = data ( cindex, : );
        cursordata.label = opt.hdr.label { chanindx ( cindex ) };
        setappdata ( handle ( cindex ), 'cursordata', cursordata );
        
        % Sets the channel color.
        set ( handle ( cindex ), 'Color', chancolor ( cindex, : ) )
    end
    
    % Sends the physiological channels to the back.
    uistack ( handle ( ismember ( chanindx, cfg.physio ) ), 'bottom' )
    
    % Sends the bad channels to the back.
    uistack ( handle ( badchan ), 'bottom' )
    
    % Sends the artifacts to the back.
    uistack ( findobj ( ha, 'Tag', 'artifact' ), 'bottom' )
    
    
    % Creates eleven ticks for the x axis.
    xTick      = linspace ( time (1), time (end), 11 );
    xTickLabel = cellstr ( num2str ( xTick', '%.2f' ) );
    
    % Creates four ticks for each channel for the y axis.
    yTick      = bsxfun ( @times, [ -1/2 -1/4 1/4 1/2 ], 1 / numel ( chanindx ) );
    yTick      = bsxfun ( @plus, centers', yTick );
    yTick      = flipud ( yTick );
    yTickLabel = [ .0 .25 .75 1 ] .* diff ( cfg.ylim ) + cfg.ylim (1);
    yTickLabel = repmat ( yTickLabel, numel ( chanindx ), 1 );
    
    % No room for ticks.
    if strcmp ( cfg.viewmode, 'component' ) || numel ( chanindx ) > 19
        yTick      = yTick      ( :, [] )';
        yTickLabel = yTickLabel ( :, [] )';
        
    % Minus/plus one tick per channel.
    elseif numel ( chanindx ) > 6
        yTick      = yTick      ( :, [ 2 3 ] )';
        yTickLabel = yTickLabel ( :, [ 2 3 ] )';
        
    % Minux/plus two ticks per channel.
    else
        yTick      = yTick      ( :, [ 1 2 3 4 ] )';
        yTickLabel = yTickLabel ( :, [ 1 2 3 4 ] )';
    end
else
    
  % the following is implemented for 2column, 3column, etcetera.
  % it also works for topographic layouts, such as CTF151

  % determine channel indices into data outside of loop
  laysels = match_str(opt.laytime.label, opt.hdr.label);

  for cindex = 1:length(chanindx)
    color = opt.chancolors(chanindx(cindex),:);
    datsel = cindex;
    laysel = laysels(cindex);

    if ~isempty(datsel) && ~isempty(laysel)

      handle = ft_plot_vector(time, plotdata(datsel, :), 'parent', ha, 'box', false, 'color', color, 'tag', 'timecourse', 'hpos', opt.laytime.pos(laysel,1), 'vpos', opt.laytime.pos(laysel,2), 'width', opt.laytime.width(laysel), 'height', opt.laytime.height(laysel), 'hlim', opt.hlim, 'vlim', opt.vlim, 'linewidth', cfg.linewidth);

      cursordata.type  = 'channel';
      cursordata.time  = time;
      cursordata.data  = plotdata ( cindex, : );
      cursordata.label = opt.hdr.label { chanindx ( cindex ) };
      setappdata ( handle ( cindex ), 'cursordata', cursordata );
    end
  end
  
    % Creates eleven ticks for the x axis.
    xTick      = linspace ( time (1), time (end), 11 );
    xTickLabel = cellstr ( num2str ( xTick', '%.2f' ) );
    
    % This layout does not allow ticks in the y axis.
    yTick = [];
    yTickLabel = [];
end

nsamplepad = sum ( isnan ( data ( 1, : ) ) );
% Sets the title of the figure.
if ~strcmp ( opt.viewmode, 'trialsegment' )
    wintitle = sprintf ( '%s %d/%d, time from %g to %g s', opt.viewmode, opt.trlop, size ( opt.trlvis, 1 ), time (1), time ( end - nsamplepad ) );
else
    wintitle = sprintf ( 'trial %d/%d: segment: %d/%d, time from %g to %g s', opt.trllock, size ( opt.trlorg, 1 ), opt.trlop, size ( opt.trlvis, 1 ), time (1), time ( end - nsamplepad ) );
end
title ( ha, wintitle );


% Sets the limits to the x axis.
xlim ( ha, time ( [ 1 end ] ) )

% Writes the ticks in the x and y axis.
set ( ha, 'xTick', xTick (:), 'xTickLabel', xTickLabel (:) )
set ( ha, 'yTick', yTick (:), 'yTickLabel', yTickLabel (:) )

end


function redraw_label ( h )

% Gets the information.
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Selects the channel information axis to draw.
ha = findobj ( h, 'Tag', 'chaninfo' );

% Deletes the old channel labels.
delete ( findobj ( ha, 'tag', 'chanlabel' ) );

% Labels are only written for component or vertical data.
if ~ismember ( cfg.viewmode, { 'component', 'vertical' } )
    return
end


% Calculates the centers for the channels.
centers  = fliplr ( ( 0.5: numel ( opt.channel ) ) / numel ( opt.channel ) );
labelpos = zeros ( size ( centers ) );

% Writes out the new channel labels.
if opt.plotLabelFlag == 1
    handle = text ( labelpos, centers, opt.channel, 'Parent', ha, 'Tag', 'chanlabel', 'HorizontalAlignment', 'right', 'FontUnits', cfg.fontunits, 'FontSize', cfg.fontsize );
    set ( handle ( ismember ( opt.channel, opt.badchan ) ), 'Color', [ 128 128 128 ] / 255 );
end
if opt.plotLabelFlag == 2
    handle = text ( labelpos ( 1: 10: end ), centers ( 1: 10: end ), opt.channel ( 1: 10: end ), 'Parent', ha, 'Tag', 'chanlabel', 'HorizontalAlignment', 'right', 'FontUnits', cfg.fontunits, 'FontSize', cfg.fontsize );
    set ( handle ( ismember ( opt.channel ( 1: 10: end ), opt.badchan ) ), 'Color', [ 128 128 128 ] / 255 );
end

% Sets the x axis limits.
xlim ( ha, [ -1 0 ] )
end


function redraw_topo ( h )

% Gets the information.
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% Labels is only written for component data.
if ~strcmp ( cfg.viewmode, 'component' )
    return
end

% Selects the channel information axis to draw.
ha = findobj ( h, 'Tag', 'chaninfo' );

% Deletes the old topographies.
delete ( findobj ( ha, 'Tag', 'topography' ) );


% Gets the channels.
% channel = opt.curdata.label;
channel = opt.channel;
chanindx = my_matchstr ( opt.hdr.label, channel );

% Sorts the channel positions according to the topology.
order = my_matchstr ( opt.layorg.label, opt.orgdata.topolabel );
order = order ( ~isnan ( order ) );
chanx = opt.layorg.pos ( order, 1 );
chany = opt.layorg.pos ( order, 2 );

% Gets only the channels present in the layout.
channels = ismember ( opt.orgdata.topolabel, opt.layorg.label );

% Gets the edges for the current components.
% zmin = nanmin ( opt.orgdata.topo ( channels, chanindx ) );
% zmax = nanmax ( opt.orgdata.topo ( channels, chanindx ) );
% zabs = nanmax ( abs ( opt.orgdata.topo ( channels, chanindx ) ) );
zmin = min ( opt.orgdata.topo ( channels, chanindx ) );
zmax = max ( opt.orgdata.topo ( channels, chanindx ) );
zabs = max ( abs ( opt.orgdata.topo ( channels, chanindx ) ) );

% Determines the color limits.
switch cfg.zlim
    case 'maxmin'
    case 'maxabs'
        zmax = zabs;
        zmin = -zmax;
    otherwise
        error ( 'Invalid component scaling method.' );
end

% Sets the global color limits, if requested.
if strcmp ( cfg.compscale, 'global' )
    zmin (:) = nanmin ( zmin );
    zmax (:) = nanmax ( zmax );
end


% Determines the position of the topography plots.
centers = flipud ( ( 0.5: numel ( chanindx ) )' / numel ( chanindx ) );
height  = 1 / numel ( chanindx );

% Disables the gradiometer warning.
oldwarn = warning ( 'off', 'MATLAB:griddata:DuplicateDataPoints' );

% Goes through each component.
for cindex = 1: numel ( chanindx )
    
    % Gets the topography for the current component and scales it.
    topography = opt.orgdata.topo ( channels, chanindx ( cindex ) );
    topography = ( topography - zmin ( cindex ) ) ./ ( zmax ( cindex ) - zmin ( cindex ) + realmin );
    
    % Gets the indexes of the nans.
    noplot = isnan ( topography );
    
    % If no channels to plot creates a flat topography.
    if all ( noplot )
        topography = zeros ( size ( topography ) );
        noplot     = false ( size ( topography ) );
    end
    
    % Plots the topography for the current component.
    ft_plot_topo ( chanx ( ~noplot ), chany ( ~noplot ), topography ( ~noplot ), 'parent', ha, 'tag', 'topography', 'mask', opt.layorg.mask, 'interplim', 'mask', 'outline', opt.layorg.outline, 'hpos', height / 2, 'vpos', centers ( cindex ), 'width', height, 'height', height, 'gridscale', 45 );
end

% Restores the warnings.
warning ( oldwarn )

% Sets the x axis limits.
xlim ( ha, [ -3 1 ] ./ numel ( chanindx ) )
caxis ( ha, [ 0 1 ] )
end



function cursortext = datacursortext ( ~, event_obj )

% Gets the position of the cursor.
position   = get ( event_obj, 'Position' );

% Gets the object metadata.
cursordata = getappdata ( event_obj.Target, 'cursordata' );

% If no cursor data does nothing.
if isempty ( cursordata )
    cursortext = '<no cursor available>';
    return
end

if strcmp ( cursordata.type, 'event' )
    
    % Gets the event information.
    type       = cursordata.eventtype;
    value      = cursordata.eventvalue;
    time       = cursordata.eventtime;
    
    % Generates the text.
    cursortext = sprintf ( 'Time = %g s\nEvent: %s\nValue: %d', time, type, value );
    
elseif strcmp ( cursordata.type, 'channel' )
    
    % Gets the selected sample.
    plottedX   = get ( event_obj.Target, 'xdata' );
    sample     = nearest ( plottedX, position (1) );
    
    % Gets the channel information.
    label      = cursordata.label;
    time       = cursordata.time ( sample );
    data       = cursordata.data ( sample );
    
    % Generates the text.
    cursortext = sprintf ( 'Time: %g s\nChannel: %s\nValue: %g', time, label, data );
    
else
    
    % Generates the default cursor text.
    cursortext = sprintf ( 'X: %g\nY: %g', position );
end
end


function keyboard_cb ( h, eventdata )

% Gets the real or virtual key.
if ( isempty ( eventdata ) && ft_platform_supports ( 'matlabversion', -Inf, '2014a' ) ) || isa ( eventdata, 'matlab.ui.eventdata.ActionData' )
    key = get ( h, 'userdata' );
else
    key = getKeyboard ( eventdata );
end


% Gets the focus back to the figure, if required.
if ~strcmp ( get ( h, 'Type' ), 'figure' )
    set ( h, 'Enable', 'off' );
    drawnow update
    set ( h, 'Enable', 'on' );
end

% Gets the data from the figure.
h   = ancestor   ( h, 'figure' );
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );


switch key
    case {'1' '2' '3' '4' '5' '6' '7' '8' '9'}
        
        % Gets the new artifact type.
        newart = str2double ( key );
        
        % If the artifact type is invalid does nothing.
        if newart > size ( opt.artdata.trial {1}, 1 ), return, end
        
        % If the artifact type is the same does nothing.
        if newart == opt.ftsel, return, end
        
        % Switches to the new artifact type.
        opt.ftsel = newart;
        
        % Redraws the artifacts.
        setappdata ( h, 'opt', opt );
        redraw_art ( h );
        
    case { 'shift+1' 'shift+2' 'shift+3' 'shift+4' 'shift+5' 'shift+6' 'shift+7' 'shift+8' 'shift+9' }
        
        % Gets the new artifact type.
        newart = str2double ( key (end) );
        
        % If the artifact type is invalid does nothing.
        if newart > size ( opt.artdata.trial {1}, 1 ), return, end
        
        % Gets the artifact vector.
        artifact = opt.artdata.trial {1} ( newart, : );
        
        % Gets the sample of the previous artifact.
        cursam = opt.trlvis ( opt.trlop, 1 );
        artsam = find ( artifact ( 1: cursam - 1 ), 1, 'last');
        
        % If no previous artifacts does nothing.
        if isempty ( artsam )
            fprintf ( 1, 'No previous %s artifact.\n', opt.artdata.label { newart } );
            return
        end
        
        % Gets the nearest trial containing the artifact.
        arttrl = find ( opt.trlvis ( :, 1 ) < artsam, 1, 'last' );
        
        % If no trial does nothing.
        if isempty ( arttrl )
            fprintf ( 1, 'No previous %s artifact.\n', opt.artdata.label { newart } );
            return
        end
        
        % Switches to the new artifact type and trial.
        opt.ftsel = newart;
        opt.trlop = arttrl;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        redraw_cb ( h );
        
    case { 'control+1' 'control+2' 'control+3' 'control+4' 'control+5' 'control+6' 'control+7' 'control+8' 'control+9' 'alt+1' 'alt+2' 'alt+3' 'alt+4' 'alt+5' 'alt+6' 'alt+7' 'alt+8' 'alt+9' }
        
        % Gets the new artifact type.
        newart = str2double ( key (end) );
        
        % If the artifact type is invalid does nothing.
        if newart > size ( opt.artdata.trial {1}, 1 ), return, end
        
        % Gets the artifact vector.
        artifact = opt.artdata.trial {1} ( newart, : );
        
        % Gets the sample of the previous artifact.
        cursam = opt.trlvis ( opt.trlop, 2 );
        artsam = cursam + find ( artifact ( cursam + 1: end ), 1, 'first');
        
        % If no previous artifacts does nothing.
        if isempty ( artsam )
            fprintf ( 1, 'No later %s artifact.\n', opt.artdata.label { newart } );
            return
        end
        
        % Gets the nearest trial containing the artifact.
        arttrl = find ( opt.trlvis ( :, 2 ) > artsam, 1, 'first' );
        
        % If no trial does nothing.
        if isempty ( arttrl )
            fprintf ( 1, 'No later %s artifact.\n', opt.artdata.label { newart } );
            return
        end
        
        % Switches to the new artifact type and trial.
        opt.ftsel = newart;
        opt.trlop = arttrl;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        redraw_cb ( h );
        
    case 'leftarrow'
        
        % If already in the first trial does nothing.
        if opt.trlop == 1, return, end
        
        % Switches to the previous trial.
        opt.trlop = opt.trlop - 1;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        redraw_cb(h, eventdata);
        
    case 'rightarrow'
        
        % If already in the last trial does nothing.
        if opt.trlop == size ( opt.trlvis, 1 ), return, end
        
        % Switches to the next trial.
        opt.trlop = opt.trlop + 1;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        redraw_cb ( h, eventdata );
        
    case 'uparrow'
        
        % Lists all the non-physiological channels.
        chans   = setdiff ( 1: numel ( opt.hdr.label ), cfg.physio, 'stable' );
        
        % Gets the list of non-physiological channels.
        chanold = match_str ( opt.hdr.label ( chans ), cfg.channel );
        
        % Gets the list of previous channels.
        minchan = min ( chanold );
        numchan = numel ( chanold );
        channew = ( 1: numchan )' + max ( 0, minchan - numchan - 1 );
        
        % If the channels don't change does nothing.
        if isequal ( channew, chanold ), return, end
        
        % Gets the real channel indexes and labels.
        channew = chans ( channew );
        cfg.channel = opt.hdr.label ( channew );
        
        % Sets the flag to rewrite the layout.
        opt.changedchanflg = true;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'downarrow'
        
        % Lists all the non-physiological channels.
        chans   = setdiff ( 1: numel ( opt.hdr.label ), cfg.physio, 'stable' );
        
        % Gets the list of non-physiological channels.
        chanold = match_str ( opt.hdr.label ( chans ), cfg.channel );
        
        % Gets the list of previous channels.
        maxchan = max ( chanold );
        numchan = numel ( chanold );
        channew = ( 1: numchan )' + min ( maxchan, numel ( chans ) - numchan );
        
        % If the channels don't change does nothing.
        if isequal ( channew, chanold ), return, end
        
        % Gets the real channel indexes and labels.
        channew = chans ( channew );
        cfg.channel = opt.hdr.label ( channew );
        
        % Sets the flag to rewrite the layout.
        opt.changedchanflg = true;
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'shift+leftarrow'
        
        % Modifies the block size.
        cfg.blocksize = cfg.blocksize * sqrt (2);
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        definetrial_cb ( h, eventdata );
        redraw_cb ( h, eventdata );
        
    case 'shift+rightarrow'
        
        % Modifies the block size.
        cfg.blocksize = cfg.blocksize / sqrt (2);
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        definetrial_cb ( h, eventdata );
        redraw_cb ( h, eventdata );
        
    case 'shift+uparrow'
        
        % Modifies the scaling.
        cfg.ylim = cfg.ylim / sqrt (2);
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'shift+downarrow'
        
        % Modifies the scaling.
        cfg.ylim = cfg.ylim * sqrt (2);
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'q'
        
        % Closes the GUI.
        cleanup_cb ( h );
        
    case 't'
        
        % Asks for the trial to show.
        if ~strcmp ( opt.viewmode, 'trialsegment' )
            text     = sprintf ( '%s to display (current trial: %d/%d)', opt.viewmode, opt.trlop, size ( opt.trlvis, 1 ) );
        else
            text     = sprintf ( 'Segment to display (current segment: %d/%d)', opt.trlop, size ( opt.trlvis, 1 ) );
        end
        response = inputdlg ( text, 'Specify', 1, cellstr ( num2str ( opt.trlop ) ) );
        
        % If no response does nothing.
        if isempty ( response ), return, end
        
        opt.trlop = str2double ( response );
        
        % If invalid response does nothing.
        if isnan ( opt.trlop ), return, end
        
        % Sanitizes the response.
        opt.trlop = min ( opt.trlop, size ( opt.trlvis, 1 ) );
        opt.trlop = max ( opt.trlop, 1 );
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        redraw_cb ( h, eventdata );
        
    case 'h'
        
        % Asks for the scale.
        text     = 'Horizontal scale';
        response = inputdlg ( text, 'Specify', 1, cellstr ( num2str ( cfg.blocksize ) ) );
        
        % If no response does nothing.
        if isempty ( response ), return, end
        
        cfg.blocksize = str2double ( response );
        
        % If invalid response does nothing.
        if isnan ( cfg.blocksize ), return, end
        
        % Sanitizes the response.
        opt.trlop = min ( opt.trlop, size ( opt.trlvis, 1 ) );
        opt.trlop = max ( opt.trlop, 1 );
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        definetrial_cb ( h, eventdata );
        redraw_cb ( h, eventdata );
        
    case 'v'
        
        % Asks for the scale.
        text     = 'Vertical scale, [ymin ymax], ''maxabs'' or ''maxmin''';
        response = inputdlg ( text, 'Specify', 1, cellstr ( sprintf ( '[ %d %d ]', cfg.ylim ) ) );
        
        % If no response does nothing.
        if isempty ( response ), return, end
        
        if strcmp ( response, 'maxmin' )
            maxval = max ( opt.curdata.trial {1} (:) );
            minval = min ( opt.curdata.trial {1} (:) );
            cfg.ylim = [ minval maxval ];
        elseif strcmp ( response, 'maxabs' )
            maxval =  max ( abs ( opt.curdata.trial {1} (:) ) );
            minval = -max ( abs ( opt.curdata.trial {1} (:) ) );
            cfg.ylim = [ minval maxval ];
        else
            cfg.ylim = str2num ( response {1} ); %#ok<ST2NM>
        end
        
        % If invalid response does nothing.
        if any ( isnan ( cfg.ylim ) ), return, end
        if numel ( cfg.ylim ) ~= 2, return, end
        
        % Redraws the channel data.
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'c'
        
        % Gets the list of available channels.
        channel = setdiff ( opt.hdr.label, opt.hdr.label ( cfg.physio ), 'stable' );
        
        % Getst he list of current channels.
        select  = my_matchstr ( channel, cfg.channel );
        
        % Asks for the new list of channels.
        select  = my_channellist ( channel, select );
        
        % If no channels selected does nothing.
        if isempty ( select  )
            fprintf ( 1, 'No channels selected. Ignoring.\n' );
            return
        end
        
        % Sets the new channel list.
        cfg.channel = channel ( select );
        
        % Redraws the channel data.
        setappdata ( h, 'opt', opt );
        setappdata ( h, 'cfg', cfg );
        redraw_cb ( h, eventdata );
        
    case 'i'
        if strcmp(cfg.viewmode, 'butterfly')
            delete(findobj(h, 'tag', 'identify'));
            % click in data and get name of nearest channel
            fprintf('click in the figure to identify the name of the closest channel\n');
            val = ginput(1);
            pos = val(1);
            % transform 'val' to match data
            val(1) = val(1) * range(opt.hlim) + opt.hlim(1);
            val(2) = val(2) * range(opt.vlim) + opt.vlim(1);
            channame = val2nearestchan(opt.curdata,val);
            channb = match_str(opt.curdata.label,channame);
            fprintf('channel name: %s\n',channame);
            redraw_cb(h, eventdata);
            ft_plot_text(pos, 0.9, channame, 'FontSize', cfg.fontsize, 'FontUnits', cfg.fontunits, 'tag', 'identify', 'interpreter', 'none', 'FontSize', cfg.fontsize, 'FontUnits', cfg.fontunits);
            if ~ishold
                hold on
                ft_plot_vector(opt.curdata.time{1}, opt.curdata.trial{1}(channb,:), 'box', false, 'tag', 'identify', 'hpos', opt.laytime.pos(1,1), 'vpos', opt.laytime.pos(1,2), 'width', opt.laytime.width(1), 'height', opt.laytime.height(1), 'hlim', opt.hlim, 'vlim', opt.vlim, 'color', 'k', 'linewidth', 2);
                hold off
            else
                ft_plot_vector(opt.curdata.time{1}, opt.curdata.trial{1}(channb,:), 'box', false, 'tag', 'identify', 'hpos', opt.laytime.pos(1,1), 'vpos', opt.laytime.pos(1,2), 'width', opt.laytime.width(1), 'height', opt.laytime.height(1), 'hlim', opt.hlim, 'vlim', opt.vlim, 'color', 'k', 'linewidth', 2);
            end
        else
            warning('only supported with cfg.viewmode=''butterfly''');
        end
        
    case 'x'
        preproc_cfg1_cb ( h, eventdata )
        
    case 's'
        
        % Toggles between selection modes.
        toggle_mode ( h )
        
    case 'p'
        
        % Toggles the projectors on/off.
        toggle_proj ( h )
        
    case 'e'
        
        % Toggles the event visibility on/off.
        toggle_event ( h )
        
    case 'control+control'
    case 'shift+shift'
    case 'alt+alt'
    otherwise
        help_cb ( h );
end
end


function help_cb ( h, eventdata ) %#ok<INUSD>
fprintf('------------------------------------------------------------------------------------\n')
fprintf('You can use the following keyboard buttons in the databrowser:\n')
fprintf('1-9                : select artifact type 1-9.\n');
fprintf('shift 1-9          : select previous artifact of type 1-9.\n');
fprintf('control 1-9        : select next artifact of type 1-9.\n');
fprintf('alt 1-9            : select next artifact of type 1-9.\n');
fprintf('arrow-left         : previous trial.\n');
fprintf('arrow-right        : next trial.\n');
fprintf('shift arrow-up     : increase vertical scaling.\n');
fprintf('shift arrow-down   : decrease vertical scaling.\n');
fprintf('shift arrow-left   : increase horizontal scaling.\n');
fprintf('shift arrow-down   : decrease horizontal scaling.\n');
fprintf('s                  : toggles between cfg.selectmode options.\n');
fprintf('q                  : quit.\n');
fprintf('------------------------------------------------------------------------------------\n')
fprintf('\n')
end


function cleanup_cb ( h, eventdata ) %#ok<INUSD>

opt = getappdata ( h, 'opt' );

% Deletes the figure, if required.
if ~opt.output
    delete ( h )
    return
end

uiresume
end


function toggle_viewmode_cb ( h, eventdata, varargin ) %#ok<INUSL>
% FIXME should be used
opt = getappdata ( h, 'opt' );
cfg = getappdata ( h, 'cfg' );

% If no new view mode does nothing.
if nargin < 3, return, end

% If invalid new view mode does nothing.
if ~ismember ( varargin {1}, { 'vertical' 'component' 'butterfly' } ), return, end


% Sets the new view mode.
cfg.viewmode = varargin{1};

% Forces the rewriting of the labels/topographies.
opt.oldchan = [];

% Redraws the channel data.
setappdata ( h, 'opt', opt );
setappdata ( h, 'cfg', cfg );
redraw_cb ( h );
end



function vectors = art2vec ( artifacts, endsample )

% Initializes the output.
vectors = false ( numel ( artifacts ), endsample );

% Goes throug each artifact type.
for tindex = 1: numel ( artifacts )
    
    % Takes the artifact definition.
    artifact = artifacts { tindex };
    
    % If no artifacts, ignores.
    if numel ( artifact ) == 0
        continue
    end
    
    % Makes sure that no artifact goes beyond the end of the data.
    artifact ( artifact ( :, 1 ) > endsample, : ) = [];
    artifact ( artifact ( :, 2 ) > endsample, 2 ) = endsample;
    
    % Goes through each artifact.
    for aindex = 1: size ( artifact, 1 )
        
        % Creates the artifact.
        vectors ( tindex, artifact ( aindex, 1 ): artifact ( aindex, 2 ) ) = true;
    end
end
end

function artifacts = vec2art ( vectors )

% Initializes the output.
artifacts = cell ( size ( vectors ( :, 1 ) ) );

% Extends the vector with zeroes.
vectors ( :, end + 2 ) = 0;
vectors = circshift ( vectors, 1, 2 );

% Gets the artifact edges.
edges = diff ( vectors, 1, 2 );

% Goes through each artifact type.
for tindex = 1: size ( edges, 1 )
    
    % Gets the rising and falling edges.
    rise = find ( edges ( tindex, : ) > 0 );
    fall = find ( edges ( tindex, : ) < 0 ) - 1;
    
    % Creates the artifact matrix.
    artifacts { tindex } = cat ( 2, rise (:), fall (:) );
end
end

function key = getKeyboard ( eventdata )

% Initializes the key value.
key = eventdata.Key;

% Sanitizes the numeric pad keys.
key = strrep ( key, 'numpad', '' );

% Adds the modifier.
if ~isempty ( eventdata.Modifier )
    key = strcat ( eventdata.Modifier {1}, '+', key );
end
end



function func = ft_getuserfun(func, prefix)

if isa(func, 'function_handle')
  % treat function handle as-is
elseif isfunction(func) && ~iscompatwrapper(func)
  func = str2func(func);
elseif isfunction([prefix '_' func]) && ~iscompatwrapper([prefix '_' func])
  func = str2func([prefix '_' func]);
elseif isfunction(['ft_' prefix '_' func])
  func = str2func(['ft_' prefix '_' func]);
else
  warning(['no function by the name ''' func ''', ''' prefix '_' func...
    ''', or ''ft_' prefix '_' func ''' could not be found']);
  func = [];
end
end

function b = isfunction(funcname)
b = ~isempty(which(funcname));
end





function [dat, label, time, cfg] = preproc(dat, label, time, cfg, begpadding, endpadding)

% Based on FieldTrip 20160222 functions:
% * preproc by  Robert Oostenveld

% compute fsample
fsample = 1./nanmean(diff(time));

if nargin<5 || isempty(begpadding)
  begpadding = 0;
end
if nargin<6 || isempty(endpadding)
  endpadding = 0;
end

if iscell(cfg)
  % recurse over the subsequent preprocessing stages
  if begpadding>0 || endpadding>0
    error('multiple preprocessing stages are not supported in combination with filter padding');
  end
  for i=1:length(cfg)
    tmpcfg = cfg{i};
    if nargout==1
      [dat                     ] = preproc(dat, label, time, tmpcfg, begpadding, endpadding);
    elseif nargout==2
      [dat, label              ] = preproc(dat, label, time, tmpcfg, begpadding, endpadding);
    elseif nargout==3
      [dat, label, time        ] = preproc(dat, label, time, tmpcfg, begpadding, endpadding);
    elseif nargout==4
      [dat, label, time, tmpcfg] = preproc(dat, label, time, tmpcfg, begpadding, endpadding);
      cfg{i} = tmpcfg;
    end
  end
  % ready with recursing over the subsequent preprocessing stages
  return
end

% set the defaults for the rereferencing options
if ~isfield(cfg, 'reref'),        cfg.reref = 'no';             end
if ~isfield(cfg, 'refchannel'),   cfg.refchannel = {};          end
if ~isfield(cfg, 'refmethod'),    cfg.refmethod = 'avg';        end
if ~isfield(cfg, 'implicitref'),  cfg.implicitref = [];         end
% set the defaults for the signal processing options
if ~isfield(cfg, 'polyremoval'),  cfg.polyremoval = 'no';       end
if ~isfield(cfg, 'polyorder'),    cfg.polyorder = 2;            end
if ~isfield(cfg, 'detrend'),      cfg.detrend = 'no';           end
if ~isfield(cfg, 'demean'),       cfg.demean  = 'no';           end
if ~isfield(cfg, 'baselinewindow'), cfg.baselinewindow = 'all'; end
if ~isfield(cfg, 'dftfilter'),    cfg.dftfilter = 'no';         end
if ~isfield(cfg, 'lpfilter'),     cfg.lpfilter = 'no';          end
if ~isfield(cfg, 'hpfilter'),     cfg.hpfilter = 'no';          end
if ~isfield(cfg, 'bpfilter'),     cfg.bpfilter = 'no';          end
if ~isfield(cfg, 'bsfilter'),     cfg.bsfilter = 'no';          end
if ~isfield(cfg, 'lpfiltord'),    cfg.lpfiltord = [];           end
if ~isfield(cfg, 'hpfiltord'),    cfg.hpfiltord = [];           end
if ~isfield(cfg, 'bpfiltord'),    cfg.bpfiltord = [];           end
if ~isfield(cfg, 'bsfiltord'),    cfg.bsfiltord = [];           end
if ~isfield(cfg, 'lpfilttype'),   cfg.lpfilttype = 'but';       end
if ~isfield(cfg, 'hpfilttype'),   cfg.hpfilttype = 'but';       end
if ~isfield(cfg, 'bpfilttype'),   cfg.bpfilttype = 'but';       end
if ~isfield(cfg, 'bsfilttype'),   cfg.bsfilttype = 'but';       end
if ~isfield(cfg, 'lpfiltdir'),    if strcmp(cfg.lpfilttype, 'firws'), cfg.lpfiltdir = 'onepass-zerophase'; else, cfg.lpfiltdir = 'twopass'; end, end
if ~isfield(cfg, 'hpfiltdir'),    if strcmp(cfg.hpfilttype, 'firws'), cfg.hpfiltdir = 'onepass-zerophase'; else, cfg.hpfiltdir = 'twopass'; end, end
if ~isfield(cfg, 'bpfiltdir'),    if strcmp(cfg.bpfilttype, 'firws'), cfg.bpfiltdir = 'onepass-zerophase'; else, cfg.bpfiltdir = 'twopass'; end, end
if ~isfield(cfg, 'bsfiltdir'),    if strcmp(cfg.bsfilttype, 'firws'), cfg.bsfiltdir = 'onepass-zerophase'; else, cfg.bsfiltdir = 'twopass'; end, end
if ~isfield(cfg, 'lpinstabilityfix'),    cfg.lpinstabilityfix = 'no';    end
if ~isfield(cfg, 'hpinstabilityfix'),    cfg.hpinstabilityfix = 'no';    end
if ~isfield(cfg, 'bpinstabilityfix'),    cfg.bpinstabilityfix = 'no';    end
if ~isfield(cfg, 'bsinstabilityfix'),    cfg.bsinstabilityfix = 'no';    end
if ~isfield(cfg, 'lpfiltdf'),     cfg.lpfiltdf = [];            end
if ~isfield(cfg, 'hpfiltdf'),     cfg.hpfiltdf = [];            end
if ~isfield(cfg, 'bpfiltdf'),     cfg.bpfiltdf = [];            end
if ~isfield(cfg, 'bsfiltdf'),     cfg.bsfiltdf = [];            end
if ~isfield(cfg, 'lpfiltwintype'),cfg.lpfiltwintype = 'hamming';end
if ~isfield(cfg, 'hpfiltwintype'),cfg.hpfiltwintype = 'hamming';end
if ~isfield(cfg, 'bpfiltwintype'),cfg.bpfiltwintype = 'hamming';end
if ~isfield(cfg, 'bsfiltwintype'),cfg.bsfiltwintype = 'hamming';end
if ~isfield(cfg, 'lpfiltdev'),    cfg.lpfiltdev = [];           end
if ~isfield(cfg, 'hpfiltdev'),    cfg.hpfiltdev = [];           end
if ~isfield(cfg, 'bpfiltdev'),    cfg.bpfiltdev = [];           end
if ~isfield(cfg, 'bsfiltdev'),    cfg.bsfiltdev = [];           end
if ~isfield(cfg, 'plotfiltresp'), cfg.plotfiltresp = 'no';      end
if ~isfield(cfg, 'usefftfilt'),   cfg.usefftfilt = 'no';        end
if ~isfield(cfg, 'medianfilter'), cfg.medianfilter  = 'no';     end
if ~isfield(cfg, 'medianfiltord'),cfg.medianfiltord = 9;        end
if ~isfield(cfg, 'dftfreq'),      cfg.dftfreq = [50 100 150];   end
if ~isfield(cfg, 'hilbert'),      cfg.hilbert = 'no';           end
if ~isfield(cfg, 'derivative'),   cfg.derivative = 'no';        end
if ~isfield(cfg, 'rectify'),      cfg.rectify = 'no';           end
if ~isfield(cfg, 'boxcar'),       cfg.boxcar = 'no';            end
if ~isfield(cfg, 'absdiff'),      cfg.absdiff = 'no';           end
if ~isfield(cfg, 'precision'),    cfg.precision = [];           end
if ~isfield(cfg, 'conv'),         cfg.conv = 'no';              end
if ~isfield(cfg, 'montage'),      cfg.montage = 'no';           end
if ~isfield(cfg, 'dftinvert'),    cfg.dftinvert = 'no';         end
if ~isfield(cfg, 'standardize'),  cfg.standardize = 'no';       end
if ~isfield(cfg, 'denoise'),      cfg.denoise = '';             end
if ~isfield(cfg, 'subspace'),     cfg.subspace = [];            end
if ~isfield(cfg, 'custom'),       cfg.custom = '';              end
if ~isfield(cfg, 'resample'),     cfg.resample = '';            end

% test whether the MATLAB signal processing toolbox is available
if strcmp(cfg.medianfilter, 'yes') && ~ft_hastoolbox('signal')
  error('median filtering requires the MATLAB signal processing toolbox');
end

% do a sanity check on the filter configuration
if strcmp(cfg.bpfilter, 'yes') && ...
    (strcmp(cfg.hpfilter, 'yes') || strcmp(cfg.lpfilter,'yes'))
  error('you should not apply both a bandpass AND a lowpass/highpass filter');
end

% do a sanity check on the hilbert transform configuration
if strcmp(cfg.hilbert, 'yes') && ~strcmp(cfg.bpfilter, 'yes')
  error('hilbert transform should be applied in conjunction with bandpass filter')
end

% do a sanity check on hilbert and rectification
if strcmp(cfg.hilbert, 'yes') && strcmp(cfg.rectify, 'yes')
  error('hilbert transform and rectification should not be applied both')
end

% do a sanity check on the rereferencing/montage
if ~strcmp(cfg.reref, 'no') && ~strcmp(cfg.montage, 'no')
  error('cfg.reref and cfg.montage are mutually exclusive')
end

% lnfilter is no longer used
if isfield(cfg, 'lnfilter') && strcmp(cfg.lnfilter, 'yes')
  error('line noise filtering using the option cfg.lnfilter is not supported any more, use cfg.bsfilter instead')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% do the rereferencing in case of EEG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~isempty(cfg.implicitref) && ~any(match_str(cfg.implicitref,label))
  label = [ label {cfg.implicitref} ];
  dat(end+1,:) = 0;
end

if strcmp(cfg.reref, 'yes')
  cfg.refchannel = ft_channelselection(cfg.refchannel, label);
  refindx = match_str(label, cfg.refchannel);
  if isempty(refindx)
    error('reference channel was not found')
  end
  dat = ft_preproc_rereference(dat, refindx, cfg.refmethod);
end

if ~strcmp(cfg.montage, 'no') && ~isempty(cfg.montage)
  % this is an alternative approach for rereferencing, with arbitrary complex linear combinations of channels
  tmp.trial = {dat};
  tmp.label = label;
  tmp = ft_apply_montage(tmp, cfg.montage, 'feedback', 'none');
  dat = tmp.trial{1};
  label = tmp.label;
  clear tmp
end

if any(any(isnan(dat)))
  % filtering is not possible for at least a selection of the data
  ft_warning('data contains NaNs, no filtering or preprocessing applied');
  
else
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % do the filtering on the padded data
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if ~isempty(cfg.denoise)
    hflag    = isfield(cfg.denoise, 'hilbert') && strcmp(cfg.denoise.hilbert, 'yes');
    datlabel = match_str(label, cfg.denoise.channel);
    reflabel = match_str(label, cfg.denoise.refchannel);
    tmpdat   = ft_preproc_denoise(dat(datlabel,:), dat(reflabel,:), hflag);
    dat(datlabel,:) = tmpdat;
  end
  
  % The filtering should in principle be done prior to the demeaning to
  % ensure that the resulting mean over the baseline window will be
  % guaranteed to be zero (even if there are filter artifacts).
  % However, the filtering benefits from the data being pulled towards zero,
  % causing less edge artifacts. That is why we start by removing the slow
  % drift, then filter, and then repeat the demean/detrend/polyremove.
  if strcmp(cfg.polyremoval, 'yes')
    nsamples  = size(dat,2);
    begsample = 1        + begpadding;
    endsample = nsamples - endpadding;
    dat = ft_preproc_polyremoval(dat, cfg.polyorder, begsample, endsample); % this will also demean and detrend
  elseif strcmp(cfg.detrend, 'yes')
    nsamples  = size(dat,2);
    begsample = 1        + begpadding;
    endsample = nsamples - endpadding;
    dat = ft_preproc_polyremoval(dat, 1, begsample, endsample); % this will also demean
  elseif strcmp(cfg.demean, 'yes')
    nsamples  = size(dat,2);
    begsample = 1        + begpadding;
    endsample = nsamples - endpadding;
    dat = ft_preproc_polyremoval(dat, 0, begsample, endsample);
  end
  
  if strcmp(cfg.medianfilter, 'yes'), dat = ft_preproc_medianfilter(dat, cfg.medianfiltord); end
  if strcmp(cfg.lpfilter, 'yes'),     dat = ft_preproc_lowpassfilter(dat, fsample, cfg.lpfreq, cfg.lpfiltord, cfg.lpfilttype, cfg.lpfiltdir, cfg.lpinstabilityfix, cfg.lpfiltdf, cfg.lpfiltwintype, cfg.lpfiltdev, cfg.plotfiltresp, cfg.usefftfilt); end
  if strcmp(cfg.hpfilter, 'yes'),     dat = ft_preproc_highpassfilter(dat, fsample, cfg.hpfreq, cfg.hpfiltord, cfg.hpfilttype, cfg.hpfiltdir, cfg.hpinstabilityfix, cfg.hpfiltdf, cfg.hpfiltwintype, cfg.hpfiltdev, cfg.plotfiltresp, cfg.usefftfilt); end
  if strcmp(cfg.bpfilter, 'yes'),     dat = ft_preproc_bandpassfilter(dat, fsample, cfg.bpfreq, cfg.bpfiltord, cfg.bpfilttype, cfg.bpfiltdir, cfg.bpinstabilityfix, cfg.bpfiltdf, cfg.bpfiltwintype, cfg.bpfiltdev, cfg.plotfiltresp, cfg.usefftfilt); end
  if strcmp(cfg.bsfilter, 'yes')
    for i=1:size(cfg.bsfreq,1)
      % apply a bandstop filter for each of the specified bands, i.e. cfg.bsfreq should be Nx2
      dat = ft_preproc_bandstopfilter(dat, fsample, cfg.bsfreq(i,:), cfg.bsfiltord, cfg.bsfilttype, cfg.bsfiltdir, cfg.bsinstabilityfix, cfg.bsfiltdf, cfg.bsfiltwintype, cfg.bsfiltdev, cfg.plotfiltresp, cfg.usefftfilt);
    end
  end
  if strcmp(cfg.polyremoval, 'yes')
    % the begin and endsample of the polyremoval period correspond to the complete data minus padding
    nsamples  = size(dat,2);
    begsample = 1        + begpadding;
    endsample = nsamples - endpadding;
    dat = ft_preproc_polyremoval(dat, cfg.polyorder, begsample, endsample);
  end
  if strcmp(cfg.detrend, 'yes')
    % the begin and endsample of the detrend period correspond to the complete data minus padding
    nsamples  = size(dat,2);
    begsample = 1        + begpadding;
    endsample = nsamples - endpadding;
    dat = ft_preproc_detrend(dat, begsample, endsample);
  end
  if strcmp(cfg.demean, 'yes')
    if ischar(cfg.baselinewindow) && strcmp(cfg.baselinewindow, 'all')
      % the begin and endsample of the baseline period correspond to the complete data minus padding
      nsamples  = size(dat,2);
      begsample = 1        + begpadding;
      endsample = nsamples - endpadding;
      dat       = ft_preproc_baselinecorrect(dat, begsample, endsample);
    else
      % determine the begin and endsample of the baseline period and baseline correct for it
      begsample = nearest(time, cfg.baselinewindow(1));
      endsample = nearest(time, cfg.baselinewindow(2));
      dat       = ft_preproc_baselinecorrect(dat, begsample, endsample);
    end
  end
  if strcmp(cfg.dftfilter, 'yes')
    datorig = dat;
    dat     = ft_preproc_dftfilter(dat, fsample, cfg.dftfreq);
    if strcmp(cfg.dftinvert, 'yes')
      dat = datorig - dat;
    end
  end
  if ~strcmp(cfg.hilbert, 'no')
    dat = ft_preproc_hilbert(dat, cfg.hilbert);
  end
  if strcmp(cfg.rectify, 'yes')
    dat = ft_preproc_rectify(dat);
  end
  if isnumeric(cfg.boxcar)
    numsmp = round(cfg.boxcar*fsample);
    if ~rem(numsmp,2)
      % the kernel should have an odd number of samples
      numsmp = numsmp+1;
    end
    % kernel = ones(1,numsmp) ./ numsmp;
    % dat    = convn(dat, kernel, 'same');
    dat = ft_preproc_smooth(dat, numsmp); % better edge behaviour
  end
  if isnumeric(cfg.conv)
    kernel = (cfg.conv(:)'./sum(cfg.conv));
    if ~rem(length(kernel),2)
      kernel = [kernel 0];
    end
    dat = convn(dat, kernel, 'same');
  end
  if strcmp(cfg.derivative, 'yes')
    dat = ft_preproc_derivative(dat, 1);
  end
  if strcmp(cfg.absdiff, 'yes')
    % this implements abs(diff(data), which is required for jump detection
    dat = abs([diff(dat, 1, 2) zeros(size(dat,1),1)]);
  end
  if strcmp(cfg.standardize, 'yes')
    dat = ft_preproc_standardize(dat, 1, size(dat,2));
  end
  if ~isempty(cfg.subspace)
    dat = ft_preproc_subspace(dat, cfg.subspace);
  end
  if ~isempty(cfg.custom)
    if ~isfield(cfg.custom, 'nargout')
      cfg.custom.nargout = 1;
    end
    if cfg.custom.nargout==1
      dat = feval(cfg.custom.funhandle, dat, cfg.custom.varargin);
    elseif cfg.custom.nargout==2
      [dat, time] = feval(cfg.custom.funhandle, dat, cfg.custom.varargin);
    end
  end
  if strcmp(cfg.resample, 'yes')
    if ~isfield(cfg, 'resamplefs')
      cfg.resamplefs = fsample./2;
    end
    if ~isfield(cfg, 'resamplemethod')
      cfg.resamplemethod = 'resample';
    end
%     [dat               ] = ft_preproc_resample(dat,  fsample, cfg.resamplefs, cfg.resamplemethod);
%     [time, dum, fsample] = ft_preproc_resample(time, fsample, cfg.resamplefs, cfg.resamplemethod);
    [dat, ~, fsample ] = ft_preproc_resample(dat,  fsample, cfg.resamplefs, cfg.resamplemethod);
    time = time (1) + ( 0: size ( dat, 2 ) - 1 ) / fsample;
  end
  if ~isempty(cfg.precision)
    % convert the data to another numeric precision, i.e. double, single or int32
    dat = cast(dat, cfg.precision);
  end
end % if any(isnan)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% remove the filter padding and do the preprocessing on the remaining trial data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if begpadding~=0 || endpadding~=0
  dat = ft_preproc_padding(dat, 'remove', begpadding, endpadding);
  if strcmp(cfg.demean, 'yes') || nargout>2
    time = ft_preproc_padding(time, 'remove', begpadding, endpadding);
  end
end
end


