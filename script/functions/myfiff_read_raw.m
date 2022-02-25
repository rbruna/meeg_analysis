function data = myfiff_read_raw ( filename, sbeg, send, chan )
%
% Read a specific raw data segment
%
% raw    - structure returned by fiff_setup_read_raw
% from   - first sample to include. If omitted, defaults to the
%          first sample in data
% to     - last sample to include. If omitted, defaults to the last
%          sample in data
% sel    - optional channel selection vector
%
% data   - returns the data matrix (channels x samples)
% times  - returns the time values corresponding to the samples (optional)

% Based on MNE-Matlab functions:
% * fiff_read_raw_segment by Matti Hamalainen & MGH Martinos Center


% Defines the FIFF constants.
FIFF     = fiff_define_constants;

% Reads the data information.
header   = myfiff_read_header ( filename );
info     = header.orig;
rawinfo  = info.raw;
% rawinfo  = fiff_setup_read_raw ( filename, true );

% Checks the input.
if nargin == 1
    sbeg     = rawinfo (1).first_samp;
    send     = rawinfo (end).last_samp;
    chan     = 1: info.nchan;
elseif nargin == 2
    send     = rawinfo (end).last_samp;
    chan     = 1: info.nchan;
elseif nargin == 3
    chan     = 1: info.nchan;
elseif nargin ~= 4
    error ( 'Incorrect number of arguments' );
end
if sbeg > send, error ( 'No data in the selected range.' ); end
nchan    = numel ( chan );


% Adds the file information to the raw data information.
for findex = 1: numel ( rawinfo )
    if isfield ( rawinfo, 'file' )
        [ rawinfo( findex ).rawdir.file ] = deal ( rawinfo ( findex ).file );
    else
        [ rawinfo( findex ).rawdir.file ] = deal ( filename );
    end
    if isfield ( rawinfo, 'num' )
        [ rawinfo( findex ).rawdir.num  ] = deal ( rawinfo ( findex ).num );
    else
        [ rawinfo( findex ).rawdir.num  ] = deal ( 0 );
    end
end

% Concatenates all the raw data directories.
rawdir   = [ rawinfo.rawdir ];

% Removes the empty data.
empty    = cellfun ( @isempty, { rawdir.ent } );
rawdir   = rawdir ( ~empty );

% Selects the data tags to read.
target   = [ rawdir.last ] >= sbeg & [ rawdir.first ] <= send;
rawdir   = rawdir ( target );

% Makes sure that the data tags are sorted.
[ ~, s ] = sort ( [ rawdir.first ] );
rawdir   = rawdir ( s );

if isfield ( rawdir, 'num' )
    [ ~, s ] = sort ( [ rawdir.num ] );
    rawdir   = rawdir ( s );
end

% Gets the position of each data tag.
binpos   = [ rawdir.ent ];
if ~isequal ( binpos.type )
    error ( 'Data is not congruent.' );
end
if binpos (1).type == FIFF.FIFFT_INT
    format   = 'int32=>int32';
    bytes    = 4;
elseif binpos (1).type == FIFF.FIFFT_DAU_PACK16
    format   = 'int16=>int16';
    bytes    = 2;
elseif binpos (1).type == FIFF.FIFFT_FLOAT
    format   = 'single=>single';
    bytes    = 4;
else
    error ( 'Unsupported data type.' );
end


% Reserves memory for the data.
bbeg     = min ( [ rawdir.first ] );
bend     = max ( [ rawdir.last ] );
data     = zeros ( nchan, bend - bbeg + 1, 'single' );

% Opens the first file to read.
fid      = fopen ( rawdir (1).file, 'rb', 'ieee-be' );

% Goes through each data tag.
for tindex = 1: numel ( rawdir )
    
    % Checks if the file name has changed.
    if tindex > 1 && ~isequal ( rawdir ( [ tindex - 1 tindex ] ).num )
        fclose ( fid );
        fid      = fopen ( rawdir ( tindex ).file, 'rb', 'ieee-be' );
    end
    
    % Calculates the number of samples of the current data tag.
    tlen     = binpos ( tindex ).size / bytes / info.nchan;
    
    % Gets the current data tag's data.
    fseek ( fid, binpos ( tindex ).pos + 16, 'bof' );
    tmpdata  = fread ( fid, [ info.nchan tlen ], format );
    
    % Gets the real-world position of the sample.
    mbeg     = rawdir ( tindex ).first - bbeg + 1;
    mend     = rawdir ( tindex ).last  - bbeg + 1;
    
    % Stores only the requested channels.
    data ( :, mbeg: mend ) = tmpdata ( chan, : );
end

% Closes the file.
fclose ( fid );

% Removes the extra samples.
data ( :, 1: sbeg - bbeg ) = [];
data ( :, send + 1 - bbeg + 1: end  ) = [];


% % Selects the data tags to read.
% target   = [ rawinfo.rawdir.last ] > sbeg & [ rawinfo.rawdir.first ] < send;
% rawdir   = rawinfo.rawdir ( target );
% 
% % Makes sure that the data tags are sorted.
% [ ~, s ] = sort ( [ rawdir.first ] );
% rawdir   = rawdir ( s );
% 
% % Checks if all the positions are aligned to a whole word (32 bit).
% binpos   = [ rawdir.ent ];
% if any ( [ binpos.type ] ~= FIFF.FIFFT_INT )
%     error ( 'Unsupported data type.' );
% end
% 
% dists    = diff ( [ binpos.pos ] );
% if any ( rem ( dists, 8 ) )
%     error ( 'Data tags not aligned.' );
% end
% 
% 
% % Reads the whole data to memory.
% fbeg     = binpos (1).pos;
% fend     = binpos ( end ).pos + 16 + binpos ( end ).size;
% flen     = fend - fbeg + 1;
% 
% fid      = fopen ( filename, 'rb', 'ieee-be' );
% fseek ( fid, fbeg, 'bof' );
% rawdata  = fread ( fid, flen / 4, 'int32=>double' );
% fclose ( fid );
% 
% % Calculates the begining and end of each data tag content.
% fbeg     = binpos (1).pos;
% bbeg     = ( [ binpos.pos ] - fbeg ) / 4 + 4 + 1;
% bend     = bbeg + ( [ binpos.size ] ) / 4 - 1;
% bran     = eval ( sprintf ( '[ %s]', sprintf ( '%i: %i ', [ bbeg; bend ] ) ) );
% 
% % Calculates the begining and end of each data in the matrix.
% mbeg     = [ rawdir.first ] - rawdir (1).first + 1;
% mend     = [ rawdir.last  ] - rawdir (1).first + 1;
% mran     = eval ( sprintf ( '[ %s]', sprintf ( '%i: %i ', [ mbeg; mend ] ) ) );
% 
% % Copies the data ignoring the metadata.
% data ( :, mran ) = reshape ( rawdata ( bran ), rawinfo.info.nchan, [] );


% % Goes through each data tag.
% for tindex = 1: numel ( rawdir )
%     
%     % Gets the beggining and end of the data in the binary stream.
%     bbeg     = ( rawdir ( tindex ).ent.pos - fbeg ) / 4 + 1 + 4;
%     bend     = bbeg + rawdir ( tindex ).ent.size / 4 - 1;
%     tmpdata  = rawdata ( bbeg: bend );
%     tmpdata  = reshape ( tmpdata, rawinfo.info.nchan, [] );
%     
%     % Gets the beginning and end of the current data tag in the matrix.
%     dbeg     = rawdir ( tindex ).first - sbeg + 1;
%     dend     = rawdir ( tindex ).last  - sbeg + 1;
%     data ( chan, dbeg: dend ) = tmpdata ( chan, : );
% end


% Aplies the calibration scaling.
data     = bsxfun ( @times, rawinfo (1).cals ( chan )', data );

if ~isempty ( rawinfo (1).comp )
    data    = rawinfo (1).comp * data;
end
if ~isempty ( rawinfo (1).proj )
    data    = rawinfo (1).proj * data;
end


% if nargout == 2
%     times = double ( sbeg: send ) / raw.info.sfreq;
% end
