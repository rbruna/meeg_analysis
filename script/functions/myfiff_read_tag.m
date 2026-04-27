function tag = myfiff_read_tag ( fid, pos )
%
% Extension of fiff_read_data to read Julian dates.
%
% Based on:
% * fiff_read_tag 1.16 by Matti Hamalainen.


% Checks the input.
if nargin > 2, error ( 'Incorrect number of arguments' ), end


% Jumps to the tag position, if provided.
if nargin == 2
    fseek ( fid, pos, 'bof' );

% Otherwise gets the current position.
else
    pos = ftell ( fid );
end


% Defines the FIFF constants.
FIFF = fiff_define_constants;

% Defines the FIFF magic numbers.
magics.mask_dtype   = 0xffff;     % 65535;      % ffff
magics.mask_matrix  = 0xffff0000; % 4294901760; % ffff0000
magics.matrix_dense = 0x4000;     % 16384;      % 4000
magics.matrix_CCS   = 0x4010;     % 16400;      % 4010
magics.matrix_RCS   = 0x4020;     % 16416;      % 4020


% Reads the tag metadata.
tag = [];
tag.kind = fread ( fid, 1, 'int32' );
tag.type = fread ( fid, 1, 'uint32' );
tag.size = fread ( fid, 1, 'int32' );
tag.next = fread ( fid, 1, 'int32' );

% If size is 0, does nothing.
if tag.size == 0, return, end


% If the tag is a matrix, rellies on MNE.
if bitand ( magics.mask_matrix, tag.type )
    tag = fiff_read_tag ( fid, pos );
    return
end


% Goes trhough the known data types.
switch tag.type
    case FIFF.FIFFT_BYTE
        tag.data = fread ( fid, tag.size, 'uint8=>uint8' );
    case FIFF.FIFFT_SHORT
        tag.data = fread ( fid, tag.size / 2, '*int16' );
    case FIFF.FIFFT_INT
        tag.data = fread ( fid, tag.size / 4, '*int32' );
    case FIFF.FIFFT_JULIAN
        tag.data = fread ( fid, tag.size / 4, '*int32' );
    case FIFF.FIFFT_USHORT
        tag.data = fread ( fid, tag.size / 2, '*uint16' );
    case FIFF.FIFFT_UINT
        tag.data = fread ( fid, tag.size / 4, '*uint32' );
    case FIFF.FIFFT_FLOAT
        tag.data = fread ( fid, tag.size / 4, 'single' );
    case FIFF.FIFFT_DOUBLE
        tag.data = fread ( fid, tag.size / 8, 'double' );
    case FIFF.FIFFT_STRING
        tag.data = fread ( fid, tag.size, '*char' )';
    case FIFF.FIFFT_DAU_PACK16
        tag.data = fread ( fid, tag.size / 2, '*int16' );
    case FIFF.FIFFT_COMPLEX_FLOAT
        tag.data = fread ( fid, tag.size / 4, 'single' );
    case FIFF.FIFFT_COMPLEX_DOUBLE
        tag.data = fread ( fid, tag.size / 8, 'double' );

    % If not implemented rellies on MNE.
    otherwise
        tag = fiff_read_tag ( fid, pos );
end


% Combines the complex types.
if ismember ( tag.type, [ FIFF.FIFFT_COMPLEX_FLOAT, FIFF.FIFFT_COMPLEX_DOUBLE ] )
    tag.data = complex ( tag.data ( 1: 2: end ), tag.data ( 2: 2: end ) );
end

% Converts the Julian date into a MATLAB datetime object.
if tag.type == FIFF.FIFFT_JULIAN
    tag.data = datetime ( tag.data, 'ConvertFrom', 'JulianDate' );
end

% Converts the Julian date into a string.
if tag.type == FIFF.FIFFT_JULIAN
    tag.data = char ( tag.data, 'yyyy-MM-dd' );
end
