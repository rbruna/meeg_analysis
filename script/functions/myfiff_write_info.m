function myfiff_write_info ( fid, info )

% Based on MNE-Matlab functions:
% * fiff_start_writing_raw by Matti Hamalainen


% Defines the FIFF constants.
FIFF = mymne_define_constants;


% Writes the essential information.
fiff_start_block ( fid, FIFF.FIFFB_MEAS );
fiff_write_id ( fid, FIFF.FIFF_BLOCK_ID );
if ~isempty ( info.meas_id )
    fiff_write_id ( fid, FIFF.FIFF_PARENT_BLOCK_ID, info.meas_id );
end

% Writes the measurement information.
fiff_start_block ( fid, FIFF.FIFFB_MEAS_INFO );

if isfield ( info, 'experimenter' )
    fiff_write_string ( fid, FIFF.FIFF_EXPERIMENTER, info.experimenter );
end
if isfield ( info, 'comment' )
    fiff_write_string ( fid, FIFF.FIFF_COMMENT, info.comment );
end


% Writes the HPI result.
if isfield ( info, 'hpi_result' )
    fiff_start_block ( fid, FIFF.FIFFB_HPI_RESULT );
    for i = 1: numel ( info.hpi_result )
        hpi_result = info.hpi_result ( i );
        for j = 1: numel ( hpi_result.dig_point )
            fiff_write_dig_point ( fid, hpi_result.dig_point (j) );
        end
        if isfield ( hpi_result, 'order' )
            fiff_write_int ( fid, FIFF.FIFF_HPI_DIGITIZATION_ORDER, hpi_result.order );
        end
        if isfield ( hpi_result, 'used' )
            fiff_write_int ( fid, FIFF.FIFF_HPI_COILS_USED ,hpi_result.used );
        end
        if isfield ( hpi_result, 'moments' )
            fiff_write_float_matrix ( fid, FIFF.FIFF_HPI_COIL_MOMENTS, hpi_result.moments );
        end
        if isfield ( hpi_result, 'goodness' )
            fiff_write_float ( fid, FIFF.FIFF_HPI_FIT_GOODNESS, hpi_result.goodness );
        end
        if isfield ( hpi_result, 'good_limit' )
            fiff_write_float ( fid, FIFF.FIFF_HPI_FIT_GOOD_LIMIT, hpi_result.good_limit );
        end
        if isfield ( hpi_result, 'dist_limit' )
            fiff_write_float ( fid, FIFF.FIFF_HPI_FIT_DIST_LIMIT, hpi_result.dist_limit );
        end
        if isfield ( hpi_result, 'accept' )
            fiff_write_int ( fid, FIFF.FIFF_HPI_FIT_ACCEPT, hpi_result.accept );
        end
        if isfield ( hpi_result, 'trans' )
            fiff_write_coord_trans ( fid, hpi_result.trans );
        end
    end
    fiff_end_block ( fid, FIFF.FIFFB_HPI_RESULT );
end


% Writes the HPI information.
if isfield ( info, 'hpi_meas' )
    fiff_start_block ( fid, FIFF.FIFFB_HPI_MEAS );
    for i = 1: numel ( info.hpi_meas )
        hpi_meas = info.hpi_meas ( i );
        if isfield ( hpi_meas, 'creator' )
            fiff_write_string ( fid, FIFF.FIFF_CREATOR,      hpi_meas.creator );
        end
        if isfield ( hpi_meas, 'sfreq' )
            fiff_write_float ( fid, FIFF.FIFF_SFREQ,        hpi_meas.sfreq );
        end
        if isfield ( hpi_meas, 'nchan' )
            fiff_write_int   ( fid, FIFF.FIFF_NCHAN,        hpi_meas.nchan );
        end
        if isfield ( hpi_meas, 'nave' )
            fiff_write_int   ( fid, FIFF.FIFF_NAVE,         hpi_meas.nave );
        end
        if isfield ( hpi_meas, 'ncoil' )
            fiff_write_int   ( fid, FIFF.FIFF_HPI_NCOIL,    hpi_meas.ncoil );
        end
        if isfield ( hpi_meas, 'first_samp' )
            fiff_write_int   ( fid, FIFF.FIFF_FIRST_SAMPLE, hpi_meas.first_samp );
        end
        if isfield ( hpi_meas, 'last_samp' )
            fiff_write_int   ( fid, FIFF.FIFF_LAST_SAMPLE,  hpi_meas.last_samp );
        end
        for j = 1: numel ( hpi_meas.hpi_coil )
            fiff_start_block ( fid, FIFF.FIFFB_HPI_COIL );
            hpi = hpi_meas.hpi_coil ( j );
            if isfield ( hpi, 'number' )
                fiff_write_int   ( fid, FIFF.FIFF_HPI_COIL_NO,    hpi.number );
            end
            if isfield ( hpi, 'epoch' )
                fiff_write_float_matrix ( fid, FIFF.FIFF_EPOCH,   hpi.epoch );
            end
            if isfield ( hpi, 'slopes' )
                fiff_write_float ( fid, FIFF.FIFF_HPI_SLOPES,     hpi.slopes );
            end
            if isfield ( hpi, 'corr_coeff' )
                fiff_write_float ( fid, FIFF.FIFF_HPI_CORR_COEFF, hpi.corr_coeff );
            end
            if isfield ( hpi, 'coil_freq' )
                fiff_write_float ( fid, FIFF.FIFF_HPI_COIL_FREQ,  hpi.coil_freq );
            end
            fiff_end_block ( fid, FIFF.FIFFB_HPI_COIL );
        end
    end
    fiff_end_block ( fid, FIFF.FIFFB_HPI_MEAS );
end


% Writes the Polhemus data.
if ~isempty ( info.dig )
    fiff_start_block ( fid, FIFF.FIFFB_ISOTRAK );
    for index = 1: numel ( info.dig )
        fiff_write_dig_point ( fid, info.dig (index) )
    end
    fiff_end_block ( fid, FIFF.FIFFB_ISOTRAK );
end


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


% Writes the patient information, if available.
if isfield ( info, 'patient' )
    patient = info.patient;
    fiff_start_block ( fid, FIFF.FIFFB_SUBJECT );
    if isfield ( patient, 'id' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_ID,    patient.id );
    end
    if isfield ( patient, 'first_name' )
        fiff_write_string ( fid, FIFF.FIFF_SUBJ_FIRST_NAME,  patient.first_name );
    end
    if isfield ( patient, 'middle_name' )
        fiff_write_string ( fid, FIFF.FIFF_SUBJ_MIDDLE_NAME, patient.middle_name );
    end
    if isfield ( patient, 'last_name' )
        fiff_write_string ( fid, FIFF.FIFF_SUBJ_LAST_NAME,   patient.last_name );
    end
    if isfield ( patient, 'birth_day' )
        fiff_write_julian ( fid, FIFF.FIFF_SUBJ_BIRTH_DAY,   patient.birth_date );
    end
    if isfield ( patient, 'sex' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_SEX,    patient.sex );
    end
    if isfield ( patient, 'hand' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_HAND,    patient.hand );
    end
    if isfield ( patient, 'weight' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_WEIGHT,    patient.weight );
    end
    if isfield ( patient, 'height' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_HEIGHT,    patient.height );
    end
    if isfield ( patient, 'comment' )
        fiff_write_string ( fid, FIFF.FIFF_SUBJ_COMMENT,    patient.comment );
    end
    if isfield ( patient, 'HIS_ID' )
        fiff_write_int   ( fid, FIFF.FIFF_SUBJ_HIS_ID,    patient.HIS_ID );
    end
    fiff_end_block ( fid, FIFF.FIFFB_SUBJECT );
end



% Writes the project information, if available.
if isfield ( info, 'project' )
    project = info.project;
    if isfield ( project, 'id' )
        fiff_write_int   ( fid, FIFF.FIFF_PROJ_ID,       project.id );
    end
    if isfield ( project, 'name' )
        fiff_write_string ( fid, FIFF.FIFF_PROJ_NAME,    project.name );
    end
    if isfield ( project, 'aim' )
        fiff_write_string ( fid, FIFF.FIFF_PROJ_AIM,     project.aim );
    end
    if isfield ( project, 'persons' )
        fiff_write_string ( fid, FIFF.FIFF_PROJ_PERSONS, project.persons );
    end
    if isfield ( project, 'comment' )
        fiff_write_string ( fid, FIFF.FIFF_PROJ_COMMENT, project.comment );
    end
end


% Writes the device-to-head transformation.
if ~isempty ( info.dev_head_t )
    fiff_write_coord_trans ( fid, info.dev_head_t );
end
if ~isempty ( info.ctf_head_t )
    fiff_write_coord_trans ( fid, info.ctf_head_t );
end



% Writes the projectors.
fiff_write_proj ( fid, info.projs );

% Writes the CTF compensation information.
fiff_write_ctf_comp ( fid, info.comps );


% % Tries to recover some information from the original file.
% [ fid2, tree ] = fiff_open ( info.filename );
% 
% if fid2 > 0
% 
%     % Writes the projectors.
%     nodes = fiff_dir_tree_find ( tree, 313 );
%     fiff_copy_tree ( fid2, tree.id, nodes, fid );
% 
%     fclose ( fid2 );
% end



% Writes the general information.
if ~isempty ( info.meas_date )
    fiff_write_int ( fid, FIFF.FIFF_MEAS_DATE, info.meas_date );
end
fiff_write_int   ( fid, FIFF.FIFF_NCHAN,     numel ( info.chs ) );
fiff_write_float ( fid, FIFF.FIFF_SFREQ,     info.sfreq );
fiff_write_float ( fid, FIFF.FIFF_LOWPASS,   info.lowpass );
fiff_write_float ( fid, FIFF.FIFF_HIGHPASS,  info.highpass );
fiff_write_float ( fid, FIFF.FIFF_LINE_FREQ, info.line_freq );
% fiff_write_int   ( fid, FIFF.FIFF_DATA_PACK, FIFF.FIFFT_FLOAT );
fiff_write_int   ( fid, FIFF.FIFF_DATA_PACK, FIFF.FIFFT_INT );



% Writes the channel information.
for index = 1: numel ( info.chs )
    fiff_write_ch_info ( fid, info.chs ( index ) );
end



% % Tries to recover some information from the original file.
% [ fid2, tree ] = fiff_open ( info.filename );
% 
% if fid2 > 0
% 
%     % Writes some unknown tags (HPI subsystem).
%     nodes = fiff_dir_tree_find ( tree, 121 );
%     fiff_copy_tree ( fid2, tree.id, nodes, fid );
% 
%     fclose ( fid2 );
% end



% Here we would write the processing history (FIFFB_PROCESSING_HISTORY).


% Writes the bad channels, if any.
if ~isempty ( info.bads )
    fiff_start_block ( fid, FIFF.FIFFB_MNE_BAD_CHANNELS );
    fiff_write_name_list ( fid, FIFF.FIFF_MNE_CH_NAME_LIST, info.bads );
    fiff_end_block ( fid, FIFF.FIFFB_MNE_BAD_CHANNELS );
end

% Closes the measurement information block.
fiff_end_block ( fid,FIFF.FIFFB_MEAS_INFO );
