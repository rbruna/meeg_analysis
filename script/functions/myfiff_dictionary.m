function dictionary = myfiff_dictionary

% Based on MNE-Python functions:
% * meas_info.py/read_meas_info by Eric Larson
% * io/proc_history.py/_read_maxfilter_record by Denis A. Engemann & Eric Larson.

FIFF  = mymne_define_constants;
dictionary = [];


% Project information block.
entry       = [];
entry.kind  = FIFF.FIFFB_MEAS_INFO;
entry.name  = 'measure';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_NCHAN;
entry.tag ( 1).name = 'nchan';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_SFREQ;
entry.tag ( 2).name = 'sfreq';
entry.tag ( 2).type = 4;
entry.tag ( 3).kind = FIFF.FIFF_DATA_PACK;
entry.tag ( 3).name = 'pack';
entry.tag ( 3).type = 3;
entry.tag ( 4).kind = FIFF.FIFF_CH_INFO;
entry.tag ( 4).name = 'chs';
entry.tag ( 4).type = 30;
entry.tag ( 5).kind = FIFF.FIFF_MEAS_DATE;
entry.tag ( 5).name = 'meas_date';
entry.tag ( 5).type = 3;
entry.tag ( 6).kind = FIFF.FIFF_SUBJECT;
entry.tag ( 6).name = 'subject';
entry.tag ( 6).type = 3;
entry.tag ( 7).kind = FIFF.FIFF_COMMENT;
entry.tag ( 7).name = 'comment';
entry.tag ( 7).type = 10;
entry.tag ( 8).kind = FIFF.FIFF_NAVE;
entry.tag ( 8).name = 'nave';
entry.tag ( 8).type = 3;
entry.tag ( 9).kind = FIFF.FIFF_FIRST_SAMPLE;
entry.tag ( 9).name = 'first_sample';
entry.tag ( 9).type = 3;
entry.tag (10).kind = FIFF.FIFF_LAST_SAMPLE;
entry.tag (10).name = 'last_sample';
entry.tag (10).type = 3;
entry.tag (11).kind = FIFF.FIFF_ASPECT_KIND;
entry.tag (11).name = 'kind';
entry.tag (11).type = 3;
entry.tag (12).kind = FIFF.FIFF_REF_EVENT;
entry.tag (12).name = 'ref_event';
entry.tag (12).type = 3;
entry.tag (13).kind = FIFF.FIFF_EXPERIMENTER;
entry.tag (13).name = 'experimenter';
entry.tag (13).type = 10;
entry.tag (14).kind = FIFF.FIFF_DIG_POINT;
entry.tag (14).name = 'digs';
entry.tag (14).type = 10;
entry.tag (15).kind = FIFF.FIFF_CH_POS;
entry.tag (15).name = 'ch_pos';
entry.tag (15).type = 10;
entry.tag (16).kind = FIFF.FIFF_HPI_SLOPES;
entry.tag (16).name = 'hpi_slopes';
entry.tag (16).type = 3;
entry.tag (17).kind = FIFF.FIFF_HPI_NCOIL;
entry.tag (17).name = 'hpi_ncoil';
entry.tag (17).type = 10;
entry.tag (18).kind = FIFF.FIFF_REQ_EVENT;
entry.tag (18).name = 'req_event';
entry.tag (18).type = 10;
entry.tag (19).kind = FIFF.FIFF_REQ_LIMIT;
entry.tag (19).name = 'req_limit';
entry.tag (19).type = 10;
entry.tag (20).kind = FIFF.FIFF_LOWPASS;
entry.tag (20).name = 'lowpass';
entry.tag (20).type = 4;
entry.tag (21).kind = FIFF.FIFF_BAD_CHS;
entry.tag (21).name = 'bads';
entry.tag (21).type = 4;
entry.tag (22).kind = FIFF.FIFF_ARTEF_REMOVAL;
entry.tag (22).name = 'artef';
entry.tag (22).type = 10;
entry.tag (23).kind = FIFF.FIFF_COORD_TRANS;
entry.tag (23).name = 'trans';
entry.tag (23).type = 35;
entry.tag (24).kind = FIFF.FIFF_HIGHPASS;
entry.tag (24).name = 'highpass';
entry.tag (24).type = 10;
entry.tag (25).kind = FIFF.FIFF_CH_CALS;
entry.tag (25).name = 'ch_cals';
entry.tag (25).type = 10;
entry.tag (26).kind = FIFF.FIFF_HPI_BAD_CHS;
entry.tag (26).name = 'hpi_bads';
entry.tag (26).type = 3;
entry.tag (27).kind = FIFF.FIFF_HPI_CORR_COEFF;
entry.tag (27).name = 'hpi_corr';
entry.tag (27).type = 10;
entry.tag (28).kind = FIFF.FIFF_EVENT_COMMENT;
entry.tag (28).name = 'event_comment';
entry.tag (28).type = 10;
entry.tag (29).kind = FIFF.FIFF_NO_SAMPLES;
entry.tag (29).name = 'nsample';
entry.tag (29).type = 3;
entry.tag (30).kind = FIFF.FIFF_FIRST_TIME;
entry.tag (30).name = 'fist_time';
entry.tag (30).type = 4;
entry.tag (31).kind = FIFF.FIFF_LINE_FREQ;
entry.tag (31).name = 'line_freq';
entry.tag (31).type = 4;

dictionary = cat ( 1, dictionary, entry );


% Project information block.
entry       = [];
entry.kind  = FIFF.FIFFB_MEAS_INFO;
entry.name  = 'project';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_PROJ_ID;
entry.tag ( 1).name = 'id';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_PROJ_NAME;
entry.tag ( 2).name = 'name';
entry.tag ( 2).type = 10;
entry.tag ( 3).kind = FIFF.FIFF_PROJ_AIM;
entry.tag ( 3).name = 'aim';
entry.tag ( 3).type = 10;
entry.tag ( 4).kind = FIFF.FIFF_PROJ_PERSONS;
entry.tag ( 4).name = 'persons';
entry.tag ( 4).type = 10;
entry.tag ( 5).kind = FIFF.FIFF_PROJ_COMMENT;
entry.tag ( 5).name = 'comment';
entry.tag ( 5).type = 10;

dictionary = cat ( 1, dictionary, entry );


% Patient information block.
entry       = [];
entry.kind  = FIFF.FIFFB_SUBJECT;
entry.name  = 'patient';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_SUBJ_ID;
entry.tag ( 1).name = 'id';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_SUBJ_FIRST_NAME;
entry.tag ( 2).name = 'first_name';
entry.tag ( 2).type = 10;
entry.tag ( 3).kind = FIFF.FIFF_SUBJ_MIDDLE_NAME;
entry.tag ( 3).name = 'middle_name';
entry.tag ( 3).type = 10;
entry.tag ( 4).kind = FIFF.FIFF_SUBJ_LAST_NAME;
entry.tag ( 4).name = 'last_name';
entry.tag ( 4).type = 10;
% entry.tag ( 5).kind = FIFF.FIFF_SUBJ_BIRTH_DAY;
entry.tag ( 5).kind = NaN;
entry.tag ( 5).name = 'bith_day';
entry.tag ( 5).type = 6;
entry.tag ( 6).kind = FIFF.FIFF_SUBJ_SEX;
entry.tag ( 6).name = 'sex';
entry.tag ( 6).type = 3;
entry.tag ( 7).kind = FIFF.FIFF_SUBJ_HAND;
entry.tag ( 7).name = 'hand';
entry.tag ( 7).type = 3;
entry.tag ( 8).kind = FIFF.FIFF_SUBJ_WEIGHT;
entry.tag ( 8).name = 'weight';
entry.tag ( 8).type = 3;
entry.tag ( 9).kind = FIFF.FIFF_SUBJ_HEIGHT;
entry.tag ( 9).name = 'height';
entry.tag ( 9).type = 3;
entry.tag ( 8).kind = FIFF.FIFF_SUBJ_COMMENT;
entry.tag ( 8).name = 'comment';
entry.tag ( 8).type = 10;
entry.tag ( 9).kind = FIFF.FIFF_SUBJ_HIS_ID;
entry.tag ( 9).name = 'HIS_ID';
entry.tag ( 9).type = 3;

dictionary = cat ( 1, dictionary, entry );


% HPI result block.
entry       = [];
entry.kind  = FIFF.FIFFB_HPI_RESULT;
entry.name  = 'hpi_result';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_DIG_POINT;
entry.tag ( 1).name = 'dig_point';
entry.tag ( 1).type = 33;
entry.tag ( 2).kind = FIFF.FIFF_HPI_DIGITIZATION_ORDER;
entry.tag ( 2).name = 'order';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_HPI_COILS_USED;
entry.tag ( 3).name = 'used';
entry.tag ( 3).type = 3;
entry.tag ( 4).kind = FIFF.FIFF_HPI_COIL_MOMENTS;
entry.tag ( 4).name = 'moments';
entry.tag ( 4).type = 0; % 1.0737e+09
entry.tag ( 5).kind = FIFF.FIFF_HPI_FIT_GOODNESS;
entry.tag ( 5).name = 'goodness';
entry.tag ( 5).type = 4;
entry.tag ( 6).kind = FIFF.FIFF_HPI_FIT_GOOD_LIMIT;
entry.tag ( 6).name = 'good_limit';
entry.tag ( 6).type = 4;
entry.tag ( 7).kind = FIFF.FIFF_HPI_FIT_DIST_LIMIT;
entry.tag ( 7).name = 'dist_limit';
entry.tag ( 7).type = 4;
entry.tag ( 8).kind = FIFF.FIFF_HPI_FIT_ACCEPT;
entry.tag ( 8).name = 'accept';
entry.tag ( 8).type = 3;
entry.tag ( 9).kind = FIFF.FIFF_COORD_TRANS;
entry.tag ( 9).name = 'trans';
entry.tag ( 9).type = 35;

dictionary = cat ( 1, dictionary, entry );


% HPI measurement block.
entry       = [];
entry.kind  = FIFF.FIFFB_HPI_MEAS;
entry.name  = 'hpi_meas';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_CREATOR;
entry.tag ( 1).name = 'creator';
entry.tag ( 1).type = 10;
entry.tag ( 2).kind = FIFF.FIFF_SFREQ;
entry.tag ( 2).name = 'sfreq';
entry.tag ( 2).type = 4;
entry.tag ( 3).kind = FIFF.FIFF_NCHAN;
entry.tag ( 3).name = 'nchan';
entry.tag ( 3).type = 3;
entry.tag ( 4).kind = FIFF.FIFF_NAVE;
entry.tag ( 4).name = 'nave';
entry.tag ( 4).type = 3;
entry.tag ( 5).kind = FIFF.FIFF_HPI_NCOIL;
entry.tag ( 5).name = 'ncoil';
entry.tag ( 5).type = 3;
entry.tag ( 6).kind = FIFF.FIFF_FIRST_SAMPLE;
entry.tag ( 6).name = 'first_samp';
entry.tag ( 6).type = 3;
entry.tag ( 7).kind = FIFF.FIFF_LAST_SAMPLE;
entry.tag ( 7).name = 'last_samp';
entry.tag ( 7).type = 3;

entry.child ( 1).kind = FIFF.FIFFB_HPI_COIL;
entry.child ( 1).name = 'hpi_coil';

dictionary = cat ( 1, dictionary, entry );


% HPI coil.
entry.kind  = FIFF.FIFFB_HPI_COIL;
entry.name  = 'hpi_coil';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_HPI_COIL_NO;
entry.tag ( 1).name = 'number';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_EPOCH;
entry.tag ( 2).name = 'epoch';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_HPI_SLOPES;
entry.tag ( 3).name = 'slopes';
entry.tag ( 3).type = 3;
entry.tag ( 4).kind = FIFF.FIFF_HPI_CORR_COEFF;
entry.tag ( 4).name = 'corr_coeff';
entry.tag ( 4).type = 3;
entry.tag ( 5).kind = FIFF.FIFF_HPI_COIL_FREQ;
entry.tag ( 5).name = 'coil_freq';
entry.tag ( 5).type = 3;

dictionary = cat ( 1, dictionary, entry );


% SSS information structure.
entry.kind  = FIFF.FIFFB_SSS_INFO;
entry.name  = 'sss_info';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_SSS_JOB;
entry.tag ( 1).name = 'job';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_SSS_FRAME;
entry.tag ( 2).name = 'frame';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_SSS_ORIGIN;
entry.tag ( 3).name = 'origin';
entry.tag ( 3).type = 4;
entry.tag ( 4).kind = FIFF.FIFF_SSS_ORD_IN;
entry.tag ( 4).name = 'in_order';
entry.tag ( 4).type = 3;
entry.tag ( 5).kind = FIFF.FIFF_SSS_ORD_OUT;
entry.tag ( 5).name = 'out_order';
entry.tag ( 5).type = 3;
entry.tag ( 6).kind = FIFF.FIFF_SSS_NMAG;
entry.tag ( 6).name = 'nmag';
entry.tag ( 6).type = 3;
entry.tag ( 7).kind = FIFF.FIFF_SSS_COMPONENTS;
entry.tag ( 7).name = 'components';
entry.tag ( 7).type = 3;
entry.tag ( 8).kind = FIFF.FIFF_SSS_NFREE;
entry.tag ( 8).name = 'nfree';
entry.tag ( 8).type = 3;
entry.tag ( 9).kind = FIFF.FIFF_HPI_FIT_GOOD_LIMIT;
entry.tag ( 9).name = 'hpi_g_limit';
entry.tag ( 9).type = 4;
entry.tag (10).kind = FIFF.FIFF_HPI_FIT_DIST_LIMIT;
entry.tag (10).name = 'hpi_dist_limit';
entry.tag (10).type = 4;

dictionary = cat ( 1, dictionary, entry );


% tSSS information structure.
entry.kind  = FIFF.FIFFB_SSS_ST_INFO;
entry.name  = 'tsss_info';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_SSS_JOB;
entry.tag ( 1).name = 'job';
entry.tag ( 1).type = 10;
entry.tag ( 2).kind = FIFF.FIFF_SSS_ST_CORR;
entry.tag ( 2).name = 'corr';
entry.tag ( 2).type = 10;
entry.tag ( 3).kind = FIFF.FIFF_SSS_ST_LENGTH;
entry.tag ( 3).name = 'bufflen';
entry.tag ( 3).type = 10;

dictionary = cat ( 1, dictionary, entry );


% CTC information structure.
entry.kind  = FIFF.FIFFB_CHANNEL_DECOUPLER;
entry.name  = 'ctc_info';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_BLOCK_ID;
entry.tag ( 1).name = 'block_id';
entry.tag ( 1).type = 31;
entry.tag ( 2).kind = FIFF.FIFF_MEAS_DATE;
entry.tag ( 2).name = 'date';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_CREATOR;
entry.tag ( 3).name = 'creator';
entry.tag ( 3).type = 10;
entry.tag ( 4).kind = FIFF.FIFF_DECOUPLER_MATRIX;
entry.tag ( 4).name = 'decoupler';
entry.tag ( 4).type = 1074790404;
entry.tag ( 5).kind = FIFF.FIFF_PROJ_ITEM_CH_NAME_LIST;
entry.tag ( 5).name = 'channel';
entry.tag ( 5).type = 10;

dictionary = cat ( 1, dictionary, entry );

% decoupler = full ( tag.data ); decoupler (end ) = 1;
% channel = tag.data ( 1: find ( tag.data == 0, 1 ) - 1 );
% channel = strsplit ( ctc_info.channel, ':' );
% channel = ctc_info.channel (:);


% CAL information structure.
entry.kind  = FIFF.FIFFB_SSS_CAL;
entry.name  = 'cal_info';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_SSS_CAL_CHANS;
entry.tag ( 1).name = 'channel';
entry.tag ( 1).type = 1073741827;
entry.tag ( 2).kind = FIFF.FIFF_SSS_CAL_CORRS;
entry.tag ( 2).name = 'corrs';
entry.tag ( 2).type = 1073741828;

dictionary = cat ( 1, dictionary, entry );


% ISOTRAK measurement.
entry.kind  = FIFF.FIFFB_ISOTRAK;
entry.name  = 'isotrak';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_MEAS_DATE;
entry.tag ( 1).name = 'date';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_DIG_POINT;
entry.tag ( 2).name = 'dig_point';
entry.tag ( 2).type = 33;
entry.tag ( 3).kind = FIFF.FIFF_MNE_COORD_FRAME;
entry.tag ( 3).name = 'frame';
entry.tag ( 3).type = 3;
entry.tag ( 4).kind = FIFF.FIFF_COORD_TRANS;
entry.tag ( 4).name = 'trans';
entry.tag ( 4).type = 0;

dictionary = cat ( 1, dictionary, entry );


% SSP projectors.
entry       = [];
entry.kind  = FIFF.FIFFB_PROJ;
entry.name  = 'projs';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_NCHAN;
entry.tag ( 1).name = 'nchan';
entry.tag ( 1).type = 3;
entry.tag ( 2).kind = FIFF.FIFF_SPHERE_ORIGIN;
entry.tag ( 2).name = 'origin';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_SPHERE_RADIUS;
entry.tag ( 3).name = 'radius';
entry.tag ( 3).type = 4;
entry.tag ( 4).kind = FIFF.FIFF_COORD_TRANS;
entry.tag ( 4).name = 'trans';
entry.tag ( 4).type = 35;

entry.child ( 1).kind = FIFF.FIFFB_PROJ_ITEM;
entry.child ( 1).name = 'proj';

dictionary = cat ( 1, dictionary, entry );


% SSP projector.
entry       = [];
entry.kind  = FIFF.FIFFB_PROJ_ITEM;
entry.name  = 'proj';
entry.tag   = [];
entry.child = [];

entry.tag ( 1).kind = FIFF.FIFF_COMMENT;
entry.tag ( 1).name = 'comment';
entry.tag ( 1).type = 10;
entry.tag ( 2).kind = FIFF.FIFF_PROJ_ITEM_KIND;
entry.tag ( 2).name = 'kind';
entry.tag ( 2).type = 3;
entry.tag ( 3).kind = FIFF.FIFF_PROJ_ITEM_TIME;
entry.tag ( 3).name = 'time';
entry.tag ( 3).type = 4;
entry.tag ( 4).kind = FIFF.FIFF_PROJ_ITEM_NVEC;
entry.tag ( 4).name = 'nvec';
entry.tag ( 4).type = 3;
entry.tag ( 5).kind = FIFF.FIFF_PROJ_ITEM_VECTORS;
entry.tag ( 5).name = 'item_vectors';
entry.tag ( 5).type = 1073741828;
entry.tag ( 6).kind = FIFF.FIFF_PROJ_ITEM_DEFINITION;
entry.tag ( 6).name = 'item_definition';
entry.tag ( 6).type = 10;
entry.tag ( 7).kind = FIFF.FIFF_PROJ_ITEM_CH_NAME_LIST;
entry.tag ( 7).name = 'channels';
entry.tag ( 7).type = 10;

dictionary = cat ( 1, dictionary, entry );
