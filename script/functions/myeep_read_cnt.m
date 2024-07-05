function data = myeep_read_cnt ( filename, header ) %#ok<INUSD>

% Based on the description of the EEP 3.x file format in:
% * cnt_riff.txt by Rainer Nowagk & Maren Grigutsch.

% Gets the EEProbe header and raw data.
rawinfo  = myeep_read_info ( filename );
rawdata  = myeep_read_raw ( filename );

% Gets the information from the system-specific header.
nchan    = rawinfo.channel_count;
nsamp    = rawinfo.sample_count;
chcalib  = cat ( 1, rawinfo.channels.calibration );


% Gets the raw data information.
offsets  = rawdata.epoch_start;
nepoch   = numel ( offsets );
sepoch   = rawdata.epoch_length;
chorder  = rawdata.channel_order;

% Gets the raw bit stream.
rawdata  = rawdata.data;

% Initializes a cell array to contain the epochs.
data     = cell ( nepoch, 1 );

% Initializes the pointer.
offset   = 0;

% Goes through each epoch but the last.
for eindex = 1: nepoch - 1
    
    % Checks the offset for this epoch.
    if offset ~= 8 * offsets ( eindex )
        error ( 'Something weird happened...' );
    end
    
    % Reads the current epoch.
    [ datum, offset ] = myeep_read_block ( rawdata, sepoch, nchan, offset );
    
    % Stores the samples.
    data { eindex } = datum;
end


% Gets the number of samples of the last epoch.
srem     = nsamp - sepoch * ( nepoch - 1 );

% Reads the last block.
datum   = myeep_read_block ( rawdata, srem, nchan, offset );

% Stores the samples.
data { end } = datum;


% Concatenates all the epochs.
data     = cat ( 1, data {:} ).';

% Reorders the channels.
data     = data ( chorder, : );

% Applies the per-channel calibration.
data     = chcalib .* double ( data );
% data     = chcalib .* single ( data );
