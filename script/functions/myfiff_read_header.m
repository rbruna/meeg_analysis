function header = myfiff_read_header ( filename )

% Based on FieldTrip functions:
% * ft_read_header by Robert Oostenveld


% Defines the FIFF constants.
FIFF = fiff_define_constants;
FIFF.FIFF_REF_ROLE        = 115;
FIFF.FIFF_REF_FILE_ID     = 116;
FIFF.FIFF_REF_FILE_NUM    = 117;
FIFF.FIFF_REF_FILE_NAME   = 118;

FIFF.FIFFV_ROLE_PREV_FILE = 1;
FIFF.FIFFV_ROLE_NEXT_FILE = 2;

% Reads the FIFF header and measurement information.
[ fid,  tree ] = fiff_open ( filename );
[ info, meas ] = fiff_read_meas_info ( fid, tree );

% Checks the file for raw data.
if ~isempty ( fiff_dir_tree_find ( meas, FIFF.FIFFB_RAW_DATA ) )
    datatype = 1;
elseif ~isempty ( fiff_dir_tree_find ( meas, FIFF.FIFFB_CONTINUOUS_DATA ) )
    datatype = 1;
    
% Checks the file for MaxShield raw data.
elseif ~isempty ( fiff_dir_tree_find ( meas, FIFF.FIFFB_SMSH_RAW_DATA ) )
    datatype = 1;
    
% Checks the file for epoched data.
elseif ~isempty ( fiff_dir_tree_find ( meas, FIFF.FIFFB_EPOCHS ) )
    datatype = 2;
    
% Checks the file for averaged data.
elseif ~isempty ( fiff_dir_tree_find ( meas, FIFF.FIFFB_EVOKED ) )
    datatype = 3;
    
% Otherwise the FIFF file doesn't contain data.
else
    error ( 'The FIFF file does not contain data.' );
end


% Checks if the filter has been processed with MaxST.
maxinfo = fiff_dir_tree_find ( meas, FIFF.FIFFB_SSS_ST_INFO );
if ~isempty ( maxinfo )
    info.maxST = true;
else
    info.maxST = false;
end


% Checks if the file is part of a splitted dataset.
reference = fiff_dir_tree_find ( meas, FIFF.FIFFB_REF );

% If part of a sequence, tries to load all the files.
if ~isempty ( reference ) && ~info.maxST
    
    % Gets the current file number.
    for rindex = 1: numel ( reference )
        tag_role = myfiff_find_tag ( fid, reference ( rindex ), FIFF.FIFF_REF_ROLE );
        tag_num  = myfiff_find_tag ( fid, reference ( rindex ), FIFF.FIFF_REF_FILE_NUM );
        
        switch tag_role.data
            case FIFF.FIFFV_ROLE_PREV_FILE, seq.prev = tag_num.data;
            case FIFF.FIFFV_ROLE_NEXT_FILE, seq.next = tag_num.data;
        end
    end
    if isfield ( seq, 'prev' ) && isfield ( seq, 'next' ) && seq.prev + 1 ~= seq.next - 1
        error ( 'Incongruent sequence descriptor.' )
    end
    if isfield ( seq, 'prev' ), seq.this = seq.prev + 1; end
    if isfield ( seq, 'next' ), seq.this = seq.next - 1; end
    
    % Uses the current file number to determine the base FIFF file name.
    if seq.this == 0
        basename   = regexprep ( filename, '.fif$', '' );
    else
        basename   = regexprep ( filename, sprintf ( '-%i.fif$', seq.this ), '' );
    end
    
    % Starts for the first file.
    nextfile   = sprintf ( '%s.fif', basename );
    nextnum    = 0;
    info.raw   = [];
    
    % Iterates indefinitely.
    while true
        
        % Reads the raw data information.
        rawinfo      = fiff_setup_read_raw ( nextfile, true );
        
        % Adds the sequence number and file name.
        rawinfo.num  = nextnum;
        rawinfo.file = nextfile;
        
        % Adds the raw data information to the FIFF header.
        info.raw     = cat ( 1, info.raw, rawinfo );
        
        % Checks for the next file in the sequence.
        [ fid, tree ] = fiff_open ( nextfile );
        [ ~,   meas ] = fiff_read_meas_info ( fid, tree );
        nextfile   = false;
        
        reference = fiff_dir_tree_find ( meas, FIFF.FIFFB_REF );
        for rindex = 1: numel ( reference )
            tag_role = myfiff_find_tag ( fid, reference ( rindex ), FIFF.FIFF_REF_ROLE );
            tag_num  = myfiff_find_tag ( fid, reference ( rindex ), FIFF.FIFF_REF_FILE_NUM );
            
            if tag_role.data == FIFF.FIFFV_ROLE_NEXT_FILE
                nextnum  = tag_num.data;
                nextfile = sprintf ( '%s-%i.fif', basename, nextnum );
            end
        end
        
        % If next file, loads its information.
        if ~nextfile, break, end
    end
end

% If stand alone file uses only its information.
if isempty ( reference ) || info.maxST
    rawinfo      = fiff_setup_read_raw ( filename );
    rawinfo.file = filename;
    info.raw     = rawinfo;
end


% Stores the data type in the FIFF header.
info.iscontinuous = datatype == 1;
info.isepoched    = datatype == 2;
info.isaverage    = datatype == 3;

if datatype == 1
    nSamples    = info.raw (end).last_samp - info.raw (1).first_samp + 1;
    nSamplesPre = 0;
    nTrials     = 1;
    
elseif datatype == 2
    error ( 'Reading of epoched FIFF files not yet implemented.' );
%     data        = fiff_read_epochs ( filename );
%     info.epochs = data;
%     
%     nSamples    = length ( data.times );
%     nSamplesPre = sum ( data.times < 0 );
%     nTrials     = size ( data.data, 1 );
    
elseif datatype == 3
    error ( 'Reading of averaged FIFF files not yet implemented.' );
%     data        = fiff_read_evoked_all ( filename );
%     
%     info.evoked = data.evoked;
%     info.info   = data.info;
%     info.varlen = ~isequal ( data.evoked.first ) || ~isequal ( data.evoked.last )
%     
%     % If the epochs are diferent treat them as continuous.
%     if info.varlen
%         nSamples    = size ( cat ( 2, data.evoked.epochs ), 2);
%         nSamplesPre = 0;
%         nTrials     = 1;
%     else
%         nSamples    = data.evoked (1).last - data.evoked (1).first + 1;
%         nSamplesPre = -data.evoked (1).first;
%         nTrials     = length ( data.evoked );
%     end
end


% Builds the FieldTrip header.
header.orig        = info;
header.label       = info.ch_names (:);
header.Fs          = info.sfreq;
header.nChans      = info.nchan;
header.nSamples    = nSamples;
header.nSamplesPre = nSamplesPre;
header.nTrials     = nTrials;
