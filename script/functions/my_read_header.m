function header = my_read_header ( filename )

% Tries to use the specific function.
if ft_filetype ( filename, 'neuromag_fif' )
    header = myfiff_read_header ( filename );
    
    % Tries to get the sensors information.
%     [ grad, elec ]     = myft_mne2grad ( header.orig, false, [] );
    [ grad, elec ]     = myfiff_read_sens ( [], header );
    
    if ~isempty ( grad )
        
        % Converts the gradiometer definition to meters.
        grad               = ft_convert_units ( grad, 'm' );
        
        % Adds the channel units, if required.
        if ~isfield ( grad, 'chanunit' )
            grad.chanunit      = repmat ( { 'unknown' }, size ( grad.chantype ) );
            grad.chanunit ( strcmp ( grad.chantype, 'megmag' ) ) = { 'T' };
            grad.chanunit ( strcmp ( grad.chantype, 'megplanar' ) ) = { 'T/m' };
        end
        
        header.grad        = grad;
    end
    if ~isempty ( elec )
        header.elec        = elec;
        header.elec.type   = 'eeg';
    end
    
elseif ft_filetype ( filename, 'egi_mff' )
    header = mymff_read_header ( filename );
    
elseif ft_filetype ( filename, 'ns_cnt' )
    header = mycnt_read_header ( filename );
    
elseif ft_filetype ( filename, 'brainvision_vhdr' ) || ft_filetype ( filename, 'brainvision_eeg' )
    header = mybv_read_header ( filename );
    
% If no specific function relies on FieldTrip.
else
    header = ft_read_header ( filename );
end


% Generates a dummy sensor definition, if required.
if ~isfield ( header, 'grad' )
    header.grad         = [];
    header.grad.label   = {};
    header.grad.chanpos = zeros ( 0, 3 );
    header.grad.chanori = zeros ( 0, 3 );
    header.grad.coilpos = zeros ( 0, 3 );
    header.grad.coilori = zeros ( 0, 3 );
    header.grad.tra     = zeros ( 0, 0 );
    header.grad.unit    = 'm';
end
if ~isfield ( header, 'elec' )
    header.elec         = [];
    header.elec.label   = {};
    header.elec.chanpos = zeros ( 0, 3 );
    header.elec.elecpos = zeros ( 0, 3 );
    header.elec.tra     = zeros ( 0, 0 );
    header.elec.unit    = 'm';
end


% Sanitizes the sensor definition.
header.grad        = ft_datatype_sens ( header.grad );
header.elec        = ft_datatype_sens ( header.elec );

% Extends the channel definitions.
if ~isfield ( header, 'chantype' )
    header.chantype    = ft_chantype ( header );
end
if ~isfield ( header, 'chanunit' )
    header.chanunit    = ft_chanunit ( header );
end

% Makes sure that all the vectors are column arrays.
if isfield ( header, 'label' )
    header.label       = header.label (:);
end
if isfield ( header, 'chantype' )
    header.chantype    = header.chantype (:);
end
if isfield ( header, 'chanunit' )
    header.chanunit    = header.chanunit (:);
end

% The metadata values must be in float precission.
header.Fs          = double ( header.Fs );
header.nSamples    = double ( header.nSamples );
header.nSamplesPre = double ( header.nSamplesPre );
header.nTrials     = double ( header.nTrials );
header.nChans      = double ( header.nChans );
