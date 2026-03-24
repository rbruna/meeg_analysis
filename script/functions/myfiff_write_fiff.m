function myfiff_write_fiff ( filename, data, info )

FIFF = fiff_define_constants;

% Starts the file.
fid     = fiff_start_file ( filename );

% Writes the information.
myfiff_write_info ( fid, info );


% Corrects the calibrations in the data.
cals    = cat ( 1, info.chs.cal ) .* cat ( 1, info.chs.range );
data    = bsxfun ( @rdivide, data, cals );

% Uses 1-second buffers.
buffer  = ceil ( info.sfreq );
from    = 0;
to      = buffer * floor ( size ( data, 2 ) / buffer );

% Starts the data block.
fiff_start_block ( fid, FIFF.FIFFB_RAW_DATA );

% If first sample is not 0.
if from ~= 0
    fiff_write_int ( fid, FIFF.FIFF_FIRST_SAMPLE, from );
end

for first = from: buffer: to - 1
%     fiff_write_float ( fid, FIFF.FIFF_DATA_BUFFER, data ( :, ( 1: buffer ) + first ) );
    fiff_write_int ( fid, FIFF.FIFF_DATA_BUFFER, data ( :, ( 1: buffer ) + first ) );
end

% Closes the data block.
fiff_end_block ( fid, FIFF.FIFFB_RAW_DATA );

% Closes the file.
fiff_end_block ( fid, FIFF.FIFFB_MEAS );
fiff_end_file ( fid );
