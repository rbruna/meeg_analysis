function [ grad, elec ] = myfiff_read_sens ( filename, header, accuracy, head )

% Based on FieldTrip functions:
% * mne2grad by Joachim Gross, Laurence Hunt, Teresa Cheung & Robert Oostenveld

% Gets the file header, if provided.
if nargin < 2
    header   = myfiff_read_header ( filename );
end
info     = header.orig;

% Gets the accuracy, if provided.
if nargin < 3
    accuracy = 0;
end
if isfinite ( accuracy ) && ~ismember ( accuracy, [ 0 1 2 ] )
    error ( 'Wrong accuracy.' );
end

% Gets the coordinate system.
if nargin < 4
    head = true;
end


% Loads the coil definitions.
if isfinite ( accuracy )
    coildef = mne_load_coil_def ( 'coil_def.dat' );
    coildef = coildef ( [ coildef.accuracy ] == accuracy );
else
    coildef = mne_load_coil_def ( 'coil_def_Elekta.dat' );
end

% Selects only the MEG channels.
megchan = info.chs ( cat ( 2, info.chs.kind ) == 1 );

if ~numel ( megchan )
    grad = [];
else
    
    % Transforms the channels to Neuromag coordinates.
    if head
        if ~isempty ( info.dev_head_t )
            megchan = fiff_transform_meg_chs ( megchan, info.dev_head_t );
        else
            warning ( 'No device to head transform available in FIFF file.' );
        end
    end
    
    % Initializes the gradiometer definition.
    grad          = [];
    grad.label    = {};
    grad.chantype = {};
    grad.chanunit = {};
    grad.chanpos  = [];
    grad.chanori  = [];
    grad.coilpos  = [];
    grad.coilori  = [];
    grad.tra      = [];
    grad.unit     = 'm';
    
    % Defines the channel types and units.
    chantypes          = [];
    chantypes.fifftype = [           2        3012        3013        3014        3022        3023        3024        6001        7001 ];
    chantypes.chantype = { 'megplanar' 'megplanar' 'megplanar' 'megplanar'    'megmag'    'megmag'    'megmag'  'megaxial'  'megaxial' };
    chantypes.chanunit = {       'T/m'       'T/m'       'T/m'       'T/m'         'T'         'T'         'T'         'T'       'T/m' };
    
    % Goes through each channel.
    for cindex = 1: numel ( megchan )
        
        % Gets the current channel definition.
        chan      = megchan ( cindex );
        chanlabel = chan.ch_name;
        chantra   = chan.coil_trans ( 1: 3, 4 )';
        chanrot   = chan.coil_trans ( 1: 3, 1: 3 );
        chantype  = chantypes.chantype ( chantypes.fifftype == chan.coil_type );
        chanunit  = chantypes.chanunit ( chantypes.fifftype == chan.coil_type );
        
        % Ignores the channel if the coil type is not known.
        if ~any ( chan.coil_type == cat ( 2, coildef.id ) )
            continue
        end
        
        
        % Gets the current coil definition.
        coil      = coildef ( chan.coil_type == cat ( 2, coildef.id ) );
        coiltra   = coil.coildefs ( :, 1 )';
        coilpos   = coil.coildefs ( :, 2: 4 );
        coilori   = coil.coildefs ( :, 5: 7 );
        
        % Rotates the prototypical coil.
        coilpos   = coilpos * chanrot';
        coilori   = coilori * chanrot';
        
        % Translates the prototypical coil.
        coilpos   = coilpos + repmat ( chantra, coil.num_points, 1 );
        
        % Gets the mean channel position and orientation.
        chanpos   = chantra;
        chanori   = mean ( coilori, 1 );
        
        % Appends the channel to the sensor definition.
        grad.label    = cat ( 1, grad.label,    chanlabel );
        grad.chantype = cat ( 1, grad.chantype, chantype  );
        grad.chanunit = cat ( 1, grad.chanunit, chanunit  );
        grad.chanpos  = cat ( 1, grad.chanpos,  chanpos   );
        grad.chanori  = cat ( 1, grad.chanori,  chanori   );
        grad.coilpos  = cat ( 1, grad.coilpos,  coilpos   );
        grad.coilori  = cat ( 1, grad.coilori,  coilori   );
        grad.tra      = blkdiag ( grad.tra, coiltra );
    end
end

% Selects only the EEG channels.
eegchan = info.chs ( cat ( 2, info.chs.kind ) == 2 );

if ~numel ( eegchan )
    elec = [];
else
    
    % Transforms the channels to Neuromag coordinates.
    if head
        if ~isempty ( info.dev_head_t )
            eegchan = fiff_transform_eeg_chs ( eegchan, info.dev_head_t );
        end
    end
    
    % Initializes the electrode definition.
    elec          = [];
    elec.label    = {};
    elec.chanunit = {};
    elec.chanpos  = [];
    elec.elecpos  = [];
    elec.tra      = [];
    elec.unit     = 'm';
    
    % Goes through each channel.
    for cindex = 1: numel ( eegchan )
        
        % TO-DO: We need to add the reference.
        
        % Gets the current channel definition.
        chan      = eegchan ( cindex );
        chanlabel = chan.ch_name;
        chanpos   = chan.eeg_loc ( :, 1 )';
        chanunit  = 'V';
        
        % Generates the electrode definition.
        elecpos   = chanpos;
        
        % Appends the channel to the sensor definition.
        elec.label    = cat ( 1, elec.label,    chanlabel );
        elec.chanunit = cat ( 1, elec.chanunit, chanunit  );
        elec.chanpos  = cat ( 1, elec.chanpos,  chanpos   );
        elec.elecpos  = cat ( 1, elec.elecpos,  elecpos   );
        elec.tra      = blkdiag ( elec.tra, 1 );
    end
end
