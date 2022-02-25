function myfiff_write_info ( fid, info )

% Based on MNE-Matlab functions:
% * fiff_start_writing_raw by Matti Hamalainen


% Defines the FIFF constants.
FIFF = fiff_define_constants;


% Writes the essential information.
fiff_start_block ( fid, FIFF.FIFFB_MEAS );
fiff_write_id ( fid, FIFF.FIFF_BLOCK_ID );
if ~isempty ( info.meas_id )
    fiff_write_id ( fid, FIFF.FIFF_PARENT_BLOCK_ID, info.meas_id );
end

% Writes the measurement information.
fiff_start_block ( fid, FIFF.FIFFB_MEAS_INFO );

% Writes the megacq parameters.
if ~isempty ( info.acq_pars ) || ~isempty ( info.acq_stim )
    fiff_start_block ( fid, FIFF.FIFFB_DACQ_PARS );
    if ~isempty ( info.acq_pars )
        fiff_write_string ( fid, FIFF.FIFF_DACQ_PARS, info.acq_pars );
    end
    if ~isempty ( info.acq_stim )
        fiff_write_string ( fid, FIFF.FIFF_DACQ_STIM, info.acq_stim );
    end
    fiff_end_block ( fid, FIFF.FIFFB_DACQ_PARS );
end

% Writes the device-to-head transformation.
if ~isempty ( info.dev_head_t )
    fiff_write_coord_trans ( fid, info.dev_head_t );
end
if ~isempty ( info.ctf_head_t )
    fiff_write_coord_trans ( fid, info.ctf_head_t );
end

% Writes the Polhemus data.
if ~isempty ( info.dig )
    fiff_start_block ( fid, FIFF.FIFFB_ISOTRAK );
    for index = 1: numel ( info.dig )
        fiff_write_dig_point ( fid, info.dig (index) )
    end
    fiff_end_block ( fid, FIFF.FIFFB_ISOTRAK );
end

% Writes the projectors.
fiff_write_proj ( fid, info.projs );

% Writes the CTF compensation information.
fiff_write_ctf_comp ( fid, info.comps );

% Writes the bad channels.
if ~isempty ( info.bads )
    fiff_start_block ( fid, FIFF.FIFFB_MNE_BAD_CHANNELS );
    fiff_write_name_list ( fid, FIFF.FIFF_MNE_CH_NAME_LIST, info.bads );
    fiff_end_block ( fid, FIFF.FIFFB_MNE_BAD_CHANNELS );
end

% Writes the general information.
fiff_write_float ( fid, FIFF.FIFF_SFREQ,     info.sfreq );
fiff_write_float ( fid, FIFF.FIFF_HIGHPASS,  info.highpass );
fiff_write_float ( fid, FIFF.FIFF_LOWPASS,   info.lowpass );
fiff_write_int   ( fid, FIFF.FIFF_NCHAN,     numel ( info.chs ) );
fiff_write_int   ( fid, FIFF.FIFF_DATA_PACK, FIFF.FIFFT_FLOAT );

if ~isempty ( info.meas_date )
    fiff_write_int ( fid, FIFF.FIFF_MEAS_DATE, info.meas_date );
end

% Writes the channel information.
for index = 1: numel ( info.chs )
    fiff_write_ch_info ( fid, info.chs ( index ) );
end

% Closes the measurement information block.
fiff_end_block ( fid,FIFF.FIFFB_MEAS_INFO );
