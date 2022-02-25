function info = mymff_read_info ( filename )

% Based on FieldTrip functions:
% * ft_read_header by Robert Oostenveld
% * read_mff_bin


% Gets the information from the signal header.
binfiles = dir ( sprintf ( '%s/signal*.bin', filename ) );
if isempty ( binfiles ), error ( 'No signals found.' ), end

rawinfo = struct ( 'filename', {}, 'header', {} );
rawinfo ( numel ( binfiles ) ).filename = [];

for sindex = 1: numel ( binfiles )
    binfile = sprintf ( '%s/%s', filename, binfiles ( sindex ).name );
    rawinfo ( sindex ).filename = binfile;
    rawinfo ( sindex ).header   = mymff_read_rawinfo ( binfile );
end

% Concatenates all the block headers.
rawinfos = cat ( 1, rawinfo.header );

% Gets the sampling frequency, number of channels and number of samples.
fsample  = reshape ( cat ( 1, rawinfos.fsample ),  [], size ( rawinfos, 2 ) );
nchannel = reshape ( cat ( 1, rawinfos.nsignals ), [], size ( rawinfos, 2 ) );
nsample  = reshape ( cat ( 1, rawinfos.nsamples ), [], size ( rawinfos, 2 ) );

% Checks the consistency of the data.
if ...
        numel ( unique ( fsample ) ) ~= 1 || ...
        size ( unique ( nchannel', 'rows' )', 2 ) ~= 1 || ...
        size ( unique ( nsample, 'rows' ), 1 ) ~= 1
    error ( 'Data segments (or files) are not consistent.' )
end

fsample  = unique ( fsample );
nchannel = unique ( nchannel', 'rows' )';
nsample  = unique ( nsample,   'rows' );

% Creates a structure with all the information.
info          = [];
info.xml      = [];
info.sensor   = [];
info.fsample  = unique ( fsample );
info.nchannel = unique ( nchannel', 'rows' )';
info.nsample  = unique ( nsample,   'rows' );
info.rawinfo  = rawinfo;
