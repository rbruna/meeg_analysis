function [ filedata, labels, event ] = mycnt_read_data ( filename, varargin )

% Based on EEGlab functions:
% * loadcnt by Sean Fitzgibbon, Arnaud Delorme
% * load_scan41

format = find ( strcmp ( varargin, 'dataformat' ), 1, 'last' );
scale  = find ( strcmp ( varargin, 'scale'      ), 1, 'last' );
sbeg   = find ( strcmp ( varargin, 'sample1'    ), 1, 'last' );
tbeg   = find ( strcmp ( varargin, 't1'         ), 1, 'last' );
slen   = find ( strcmp ( varargin, 'ldnsamples' ), 1, 'last' );
tlen   = find ( strcmp ( varargin, 'lddur'      ), 1, 'last' );

if ~isempty ( format ) && format < numel ( varargin )
    format = varargin { format + 1 };
else
    format = false;
end

if ~isempty ( scale ) && scale < numel ( varargin )
    scale  = varargin { scale + 1 };
else
    scale  = true;
end

if ~isempty ( sbeg ) && sbeg < numel ( varargin )
    sbeg   = varargin { sbeg + 1 };
else
    sbeg   = 0;
end

if ~isempty ( tbeg ) && tbeg < numel ( varargin )
    tbeg   = varargin { tbeg + 1 };
else
    tbeg   = 0;
end

if ~isempty ( slen ) && slen < numel ( varargin )
    slen   = varargin { slen + 1 };
else
    slen   = inf;
end

if ~isempty ( tlen ) && tlen < numel ( varargin )
    tlen   = varargin { tlen + 1 };
else
    tlen   = true;
end

% Forces 32 bits.
format = 'int32';

% Gets the file path and the file base name.
[ filepath, basename ] = fileparts ( filename );

% Opens the file to read.
fid = fopen ( filename, 'r', 'l' );

% Reads the header.
header.rev               = fread ( fid, 12, 'char'   );
header.nextfile          = fread ( fid,  1, 'long'   );
header.prevfile          = fread ( fid,  1, 'ulong'  );
header.type              = fread ( fid,  1, 'char'   );
header.id                = fread ( fid, 20, 'char'   );
header.oper              = fread ( fid, 20, 'char'   );
header.doctor            = fread ( fid, 20, 'char'   );
header.referral          = fread ( fid, 20, 'char'   );
header.hospital          = fread ( fid, 20, 'char'   );
header.patient           = fread ( fid, 20, 'char'   );
header.age               = fread ( fid,  1, 'short'  );
header.sex               = fread ( fid,  1, 'char'   );
header.hand              = fread ( fid,  1, 'char'   );
header.med               = fread ( fid, 20, 'char'   );
header.category          = fread ( fid, 20, 'char'   );
header.state             = fread ( fid, 20, 'char'   );
header.label             = fread ( fid, 20, 'char'   );
header.date              = fread ( fid, 10, 'char'   );
header.time              = fread ( fid, 12, 'char'   );
header.mean_age          = fread ( fid,  1, 'float'  );
header.stdev             = fread ( fid,  1, 'float'  );
header.n                 = fread ( fid,  1, 'short'  );
header.compfile          = fread ( fid, 38, 'char'   );
header.spectwincomp      = fread ( fid,  1, 'float'  );
header.meanaccuracy      = fread ( fid,  1, 'float'  );
header.meanlatency       = fread ( fid,  1, 'float'  );
header.sortfile          = fread ( fid, 46, 'char'   );
header.numevents         = fread ( fid,  1, 'int'    );
header.compoper          = fread ( fid,  1, 'char'   );
header.avgmode           = fread ( fid,  1, 'char'   );
header.review            = fread ( fid,  1, 'char'   );
header.nsweeps           = fread ( fid,  1, 'ushort' );
header.compsweeps        = fread ( fid,  1, 'ushort' );
header.acceptcnt         = fread ( fid,  1, 'ushort' );
header.rejectcnt         = fread ( fid,  1, 'ushort' );
header.pnts              = fread ( fid,  1, 'ushort' );
header.nchannels         = fread ( fid,  1, 'ushort' );
header.avgupdate         = fread ( fid,  1, 'ushort' );
header.domain            = fread ( fid,  1, 'char'   );
header.variance          = fread ( fid,  1, 'char'   );
header.rate              = fread ( fid,  1, 'ushort' ); % A USER CLAIMS THAT SAMPLING RATE CAN BE 
header.scale             = fread ( fid,  1, 'double' ); % FRACTIONAL IN NEUROSCAN WHICH IS 
header.veogcorrect       = fread ( fid,  1, 'char'   );   % OBVIOUSLY NOT POSSIBLE HERE (BUG 606)
header.heogcorrect       = fread ( fid,  1, 'char'   );
header.aux1correct       = fread ( fid,  1, 'char'   );
header.aux2correct       = fread ( fid,  1, 'char'   );
header.veogtrig          = fread ( fid,  1, 'float'  );
header.heogtrig          = fread ( fid,  1, 'float'  );
header.aux1trig          = fread ( fid,  1, 'float'  );
header.aux2trig          = fread ( fid,  1, 'float'  );
header.heogchnl          = fread ( fid,  1, 'short'  );
header.veogchnl          = fread ( fid,  1, 'short'  );
header.aux1chnl          = fread ( fid,  1, 'short'  );
header.aux2chnl          = fread ( fid,  1, 'short'  );
header.veogdir           = fread ( fid,  1, 'char'   );
header.heogdir           = fread ( fid,  1, 'char'   );
header.aux1dir           = fread ( fid,  1, 'char'   );
header.aux2dir           = fread ( fid,  1, 'char'   );
header.veog_n            = fread ( fid,  1, 'short'  );
header.heog_n            = fread ( fid,  1, 'short'  );
header.aux1_n            = fread ( fid,  1, 'short'  );
header.aux2_n            = fread ( fid,  1, 'short'  );
header.veogmaxcnt        = fread ( fid,  1, 'short'  );
header.heogmaxcnt        = fread ( fid,  1, 'short'  );
header.aux1maxcnt        = fread ( fid,  1, 'short'  );
header.aux2maxcnt        = fread ( fid,  1, 'short'  );
header.veogmethod        = fread ( fid,  1, 'char'   );
header.heogmethod        = fread ( fid,  1, 'char'   );
header.aux1method        = fread ( fid,  1, 'char'   );
header.aux2method        = fread ( fid,  1, 'char'   );
header.ampsensitivity    = fread ( fid,  1, 'float'  );
header.lowpass           = fread ( fid,  1, 'char'   );
header.highpass          = fread ( fid,  1, 'char'   );
header.notch             = fread ( fid,  1, 'char'   );
header.autoclipadd       = fread ( fid,  1, 'char'   );
header.baseline          = fread ( fid,  1, 'char'   );
header.offstart          = fread ( fid,  1, 'float'  );
header.offstop           = fread ( fid,  1, 'float'  );
header.reject            = fread ( fid,  1, 'char'   );
header.rejstart          = fread ( fid,  1, 'float'  );
header.rejstop           = fread ( fid,  1, 'float'  );
header.rejmin            = fread ( fid,  1, 'float'  );
header.rejmax            = fread ( fid,  1, 'float'  );
header.trigtype          = fread ( fid,  1, 'char'   );
header.trigval           = fread ( fid,  1, 'float'  );
header.trigchnl          = fread ( fid,  1, 'char'   );
header.trigmask          = fread ( fid,  1, 'short'  );
header.trigisi           = fread ( fid,  1, 'float'  );
header.trigmin           = fread ( fid,  1, 'float'  );
header.trigmax           = fread ( fid,  1, 'float'  );
header.trigdir           = fread ( fid,  1, 'char'   );
header.autoscale         = fread ( fid,  1, 'char'   );
header.n2                = fread ( fid,  1, 'short'  );
header.dir               = fread ( fid,  1, 'char'   );
header.dispmin           = fread ( fid,  1, 'float'  );
header.dispmax           = fread ( fid,  1, 'float'  );
header.xmin              = fread ( fid,  1, 'float'  );
header.xmax              = fread ( fid,  1, 'float'  );
header.automin           = fread ( fid,  1, 'float'  );
header.automax           = fread ( fid,  1, 'float'  );
header.zmin              = fread ( fid,  1, 'float'  );
header.zmax              = fread ( fid,  1, 'float'  );
header.lowcut            = fread ( fid,  1, 'float'  );
header.highcut           = fread ( fid,  1, 'float'  );
header.common            = fread ( fid,  1, 'char'   );
header.savemode          = fread ( fid,  1, 'char'   );
header.manmode           = fread ( fid,  1, 'char'   );
header.ref               = fread ( fid, 10, 'char'   );
header.rectify           = fread ( fid,  1, 'char'   );
header.displayxmin       = fread ( fid,  1, 'float'  );
header.displayxmax       = fread ( fid,  1, 'float'  );
header.phase             = fread ( fid,  1, 'char'   );
header.screen            = fread ( fid, 16, 'char'   );
header.calmode           = fread ( fid,  1, 'short'  );
header.calmethod         = fread ( fid,  1, 'short'  );
header.calupdate         = fread ( fid,  1, 'short'  );
header.calbaseline       = fread ( fid,  1, 'short'  );
header.calsweeps         = fread ( fid,  1, 'short'  );
header.calattenuator     = fread ( fid,  1, 'float'  );
header.calpulsevolt      = fread ( fid,  1, 'float'  );
header.calpulsestart     = fread ( fid,  1, 'float'  );
header.calpulsestop      = fread ( fid,  1, 'float'  );
header.calfreq           = fread ( fid,  1, 'float'  );
header.taskfile          = fread ( fid, 34, 'char'   );
header.seqfile           = fread ( fid, 34, 'char'   );
header.spectmethod       = fread ( fid,  1, 'char'   );
header.spectscaling      = fread ( fid,  1, 'char'   );
header.spectwindow       = fread ( fid,  1, 'char'   );
header.spectwinlength    = fread ( fid,  1, 'float'  );
header.spectorder        = fread ( fid,  1, 'char'   );
header.notchfilter       = fread ( fid,  1, 'char'   );
header.headgain          = fread ( fid,  1, 'short'  );
header.additionalfiles   = fread ( fid,  1, 'int'    );
header.unused            = fread ( fid,  5, 'char'   );
header.fspstopmethod     = fread ( fid,  1, 'short'  );
header.fspstopmode       = fread ( fid,  1, 'short'  );
header.fspfvalue         = fread ( fid,  1, 'float'  );
header.fsppoint          = fread ( fid,  1, 'short'  );
header.fspblocksize      = fread ( fid,  1, 'short'  );
header.fspp1             = fread ( fid,  1, 'ushort' );
header.fspp2             = fread ( fid,  1, 'ushort' );
header.fspalpha          = fread ( fid,  1, 'float'  );
header.fspnoise          = fread ( fid,  1, 'float'  );
header.fspv1             = fread ( fid,  1, 'short'  );
header.montage           = fread ( fid, 40, 'char'   );
header.eventfile         = fread ( fid, 40, 'char'   );
header.fratio            = fread ( fid,  1, 'float'  );
header.minor_rev         = fread ( fid,  1, 'char'   );
header.eegupdate         = fread ( fid,  1, 'short'  );
header.compressed        = fread ( fid,  1, 'char'   );
header.xscale            = fread ( fid,  1, 'float'  );
header.yscale            = fread ( fid,  1, 'float'  );
header.xsize             = fread ( fid,  1, 'float'  );
header.ysize             = fread ( fid,  1, 'float'  );
header.acmode            = fread ( fid,  1, 'char'   );
header.commonchnl        = fread ( fid,  1, 'uchar'  );
header.xtics             = fread ( fid,  1, 'char'   );
header.xrange            = fread ( fid,  1, 'char'   );
header.ytics             = fread ( fid,  1, 'char'   );
header.yrange            = fread ( fid,  1, 'char'   );
header.xscalevalue       = fread ( fid,  1, 'float'  );
header.xscaleinterval    = fread ( fid,  1, 'float'  );
header.yscalevalue       = fread ( fid,  1, 'float'  );
header.yscaleinterval    = fread ( fid,  1, 'float'  );
header.scaletoolx1       = fread ( fid,  1, 'float'  );
header.scaletooly1       = fread ( fid,  1, 'float'  );
header.scaletoolx2       = fread ( fid,  1, 'float'  );
header.scaletooly2       = fread ( fid,  1, 'float'  );
header.port              = fread ( fid,  1, 'short'  );
header.numsamples        = fread ( fid,  1, 'ulong'  );
header.filterflag        = fread ( fid,  1, 'char'   );
header.lowcutoff         = fread ( fid,  1, 'float'  );
header.lowpoles          = fread ( fid,  1, 'short'  );
header.highcutoff        = fread ( fid,  1, 'float'  );
header.highpoles         = fread ( fid,  1, 'short'  );
header.filtertype        = fread ( fid,  1, 'char'   );
header.filterdomain      = fread ( fid,  1, 'char'   );
header.snrflag           = fread ( fid,  1, 'char'   );
header.coherenceflag     = fread ( fid,  1, 'char'   );
header.continuoustype    = fread ( fid,  1, 'char'   );
header.eventtablepos     = fread ( fid,  1, 'ulong'  );
header.continuousseconds = fread ( fid,  1, 'float'  );
header.channeloffset     = fread ( fid,  1, 'long'   );
header.autocorrectflag   = fread ( fid,  1, 'char'   );
header.dcthreshold       = fread ( fid,  1, 'uchar'  );

% Initializes the channel information structure.
channel = struct ( 'lab', {} );
channel ( header.nchannels ).lab = [];

% Gets the header information for each channel.
for cindex = 1: header.nchannels
    channel ( cindex ).lab            = fread ( fid, 10, 'char'   );
    channel ( cindex ).reference      = fread ( fid,  1, 'char'   );
    channel ( cindex ).skip           = fread ( fid,  1, 'char'   );
    channel ( cindex ).reject         = fread ( fid,  1, 'char'   );
    channel ( cindex ).display        = fread ( fid,  1, 'char'   );
    channel ( cindex ).bad            = fread ( fid,  1, 'char'   );
    channel ( cindex ).n              = fread ( fid,  1, 'ushort' );
    channel ( cindex ).avg_reference  = fread ( fid,  1, 'char'   );
    channel ( cindex ).clipadd        = fread ( fid,  1, 'char'   );
    channel ( cindex ).x_coord        = fread ( fid,  1, 'float'  );
    channel ( cindex ).y_coord        = fread ( fid,  1, 'float'  );
    channel ( cindex ).veog_wt        = fread ( fid,  1, 'float'  );
    channel ( cindex ).veog_std       = fread ( fid,  1, 'float'  );
    channel ( cindex ).snr            = fread ( fid,  1, 'float'  );
    channel ( cindex ).heog_wt        = fread ( fid,  1, 'float'  );
    channel ( cindex ).heog_std       = fread ( fid,  1, 'float'  );
    channel ( cindex ).baseline       = fread ( fid,  1, 'short'  );
    channel ( cindex ).filtered       = fread ( fid,  1, 'char'   );
    channel ( cindex ).fsp            = fread ( fid,  1, 'char'   );
    channel ( cindex ).aux1_wt        = fread ( fid,  1, 'float'  );
    channel ( cindex ).aux1_std       = fread ( fid,  1, 'float'  );
    channel ( cindex ).sensitivity    = fread ( fid,  1, 'float'  );
    channel ( cindex ).gain           = fread ( fid,  1, 'char'   );
    channel ( cindex ).hipass         = fread ( fid,  1, 'char'   );
    channel ( cindex ).lopass         = fread ( fid,  1, 'char'   );
    channel ( cindex ).page           = fread ( fid,  1, 'uchar'  );
    channel ( cindex ).size           = fread ( fid,  1, 'uchar'  );
    channel ( cindex ).impedance      = fread ( fid,  1, 'uchar'  );
    channel ( cindex ).physicalchnl   = fread ( fid,  1, 'uchar'  );
    channel ( cindex ).rectify        = fread ( fid,  1, 'char'   );
    channel ( cindex ).calib          = fread ( fid,  1, 'float'  );
    
    % Sanitizes the lab name.
    channel ( cindex ).lab            = deblank ( char ( channel ( cindex ).lab' ) );
end

% Stores the current position as the beginning of the data.
dbeg = ftell ( fid );

% Tries to find out if the data is 16 or 32 bits.
if ~format
    
    % Defaults to 16 bits.
    format = 'int16';
    
    % Jumps to the 32 buts flag.
    fseek ( fid, header.nextfile + 52, 'bof' );
    
    % Checks the flag.
    if header.nextfile && fread ( fid,  1, 'char' ) == 1
        format = 'int32';
    end
end


% Calculates the beginning and end of the data of interest.
if isempty ( sbeg )
    sbeg = round ( tbeg * header.rate );
end
if isempty ( slen ) && ~isempty ( tlen )
    slen = round ( tlen * header.rate ); 
end

% Gets the end of the data from the position of the events table.
dend = header.eventtablepos;

% Corrects the end if the data if interst, if needed..
if dend
    if strcmpi ( format, 'int16' )
        nums    = floor ( ( dend - dbeg ) / header.nchannels / 2 );
    else
        nums    = floor ( ( dend - dbeg ) / header.nchannels / 4 );
    end
    if slen > nums - sbeg
        slen = nums - sbeg;
    end
end

% Calculates the length of the data of interest.
slen = slen - sbeg;


% Calculates the shift to the data of interest.
if strcmpi ( format, 'int16' )
    pbeg = sbeg * 2 * header.nchannels;
else
    pbeg = sbeg * 4 * header.nchannels;
end

% Jumps to the beginning of the data of interest.
fseek ( fid, dbeg, 'bof' );
fseek ( fid, pbeg, 'cof' );

% Reads the data.
data = fread ( fid, [ header.nchannels slen ], format );

% Scales the data, if requested.
if scale
    
    % Gets the baseline and the scaling factor.
    baseline = [ channel.baseline ]';
    sensit   = [ channel.sensitivity ]';
    calib    = [ channel.calib ]';
    
    % Removes the baseline and scales the data.
    data     = bsxfun ( @minus, data, baseline );
    data     = bsxfun ( @times, data, sensit .* calib / 204.8 );
end



% Initializes the events structure.
event = struct ( 'stimtype', {}, 'keyboard', {}, 'keypad_accept', {}, 'accept_ev1', {}, 'offset', {}, 'type', {}, 'code', {}, 'latency', {}, 'epochevent', {}, 'accept', {}, 'accuracy', {} );

% Gets the pointer to the beginning of the events table.
ET_offset = header.prevfile * pow2 (32) + header.eventtablepos;    % prevfile contains high order bits of event table offset, eventtablepos contains the low order bits

% If not zero reads the events table.
if ET_offset
    
    % Jumps to the beginning of the table.
    fseek ( fid, ET_offset, 'bof' ); 
    
    % Gets the metadata of the table.
    eT.teeg   = fread ( fid, 1, 'uchar' );
    eT.size   = fread ( fid, 1, 'ulong' );
    eT.offset = fread ( fid, 1, 'ulong' );
    
    % Calculates the number of events
    if eT.teeg == 1
        nevents = eT.size / 8;
    else
        nevents = eT.size / 19;
    end
    
    % Reserves memory for the events.
    event ( nevents ).stimtype = [];
    
    % Reads the events.
    for eindex = 1: nevents
        event ( eindex ).stimtype      = fread ( fid, 1, 'ushort' );
        event ( eindex ).keyboard      = fread ( fid, 1, 'char'   );
        temp                           = fread ( fid, 1, 'uint8'  );
        event ( eindex ).keypad_accept = bitand ( 15, temp );
        event ( eindex ).accept_ev1    = bitshift ( temp, -4 );
        event ( eindex ).offset        = fread ( fid, 1, 'long'   );
        
        % Events of type 1 end here.
        if eT.teeg == 1
            continue
        end
        
        event ( eindex ).type          = fread ( fid, 1, 'short'  );
        event ( eindex ).code          = fread ( fid, 1, 'short'  );
        event ( eindex ).latency       = fread ( fid, 1, 'float'  );
        event ( eindex ).epochevent    = fread ( fid, 1, 'char'   );
        event ( eindex ).accept        = fread ( fid, 1, 'char'   );
        event ( eindex ).accuracy      = fread ( fid, 1, 'char'   );
        
        % Events of type 3 offset encodes the global sample frame.
        if eT.teeg == 3
            if strcmp ( format, 'int16' )
                event ( eindex ).offset = event ( eindex ).offset * 2 * header.nchannels;
            else
                event ( eindex ).offset = event ( eindex ).offset * 4 * header.nchannels;
            end
        end
        
        % Converts the offset from bytes to samples.
        if strcmpi ( format, 'int16' )
            event ( eindex ).offset = ( event ( eindex ).offset - dbeg ) / ( 2 * header.nchannels ) - sbeg;
        else
            event ( eindex ).offset = ( event ( eindex ).offset - dbeg ) / ( 4 * header.nchannels ) - sbeg;
        end;
    end
    
    if ~isempty ( event ) && sbeg ~= 0
        warning ( 'Events imported with a time shift might be innacurate.' );
    end;
end


% If no events in the file looks for a ev2 file.
if isempty ( event ) && exist ( sprintf ( '%s/%s.ev2', filepath, basename ), 'file' )
    
    % Creates a dummy event metadata.
    eT = [];
    
    % Opens the file to read.
    fid = fopen ( sprintf ( '%s/%s.ev2', filepath, basename ), 'r' );
    
    % Goes through each line.
    while true
        
        % Reads a line from the events file.
        line = fgetl ( fid );
        
        % If no more lines exits.
        if ~ischar ( line ), break, end
        
        % Sanitizes the line.
        line = strtrim ( line );
        
        % Checks if the line is a comment.
        if strcmp ( line (1), '#' ), continue, end
        
        % Search the fields in the line.
        line = sscanf ( line, '%i %i %i %i %i %i %i %i %f %i %i %i' );
        
        % If the format is incorrect ignores the line.
        if isempty ( line ), continue, end
        
        % Gets the index of the event.
        eindex = line (1);
        
        % Stores the event information
        event ( eindex ).stimtype      = line (2);
        event ( eindex ).keyboard      = line (3);
        event ( eindex ).keypad_accept = line (4);
        event ( eindex ).accept_ev1    = line (5);
        event ( eindex ).offset        = line (6);
        event ( eindex ).type          = line (7);
        event ( eindex ).code          = line (8);
        event ( eindex ).latency       = line (9);
        event ( eindex ).epochevent    = line (10);
        event ( eindex ).accept        = line (11);
        event ( eindex ).accuracy      = line (12);
    end
end


% Reads the file tag.
fseek ( fid, -1, 'eof' );
tag = fread ( fid, 'char' );

filedata.header     = header;
filedata.electloc   = channel;
filedata.data       = data;
filedata.event      = event;
filedata.Teeg       = eT;
filedata.tag        = tag;
filedata.ldnsamples = size ( data, 2 );

% List the channels.
labels = char ( filedata.electloc.lab );

% Closes the file.
fclose ( fid );
