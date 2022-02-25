function data = myft_load ( filename )

% Generates the MAT file and binary file filanames.
basefile = regexprep ( filename, '(.mat$)', '' );
matfile  = sprintf ( '%s.mat', basefile );
binfile  = sprintf ( '%s.dat', basefile );

% Loads the file.
data     = load ( matfile );

% Goes through each field.
fields = fieldnames ( data );
for findex = 1: numel ( fields )
    
    if strcmp ( fields { findex }, 'mriinfo' )
        fields { findex } = [];
        continue
    end 
    
    % Finds out if the field contains FieldTrip raw data.
    if ~ft_datatype ( data.( fields { findex } ), 'raw' )
        fields { findex } = [];
    end
end

% Ignores the fields not containing raw data.
fields ( cellfun ( @isempty, fields ) ) = [];

% Ignores the fields with data.
for findex = 1: numel ( fields )
    if numel ( data.( fields { findex } ).trial {1} ) ~= 4
        fields { findex } = [];
    end
end

% Ignores the fields not containing raw data.
fields ( cellfun ( @isempty, fields ) ) = [];

% Loads the trials from the binary file, if any.
if numel ( fields )
    
    % Opens the binary file to write.
    fid = fopen ( binfile, 'rb', 'ieee-le' );
    
    % Loads the trials from the binary file.
    for findex = 1: numel ( fields )
        data.( fields { findex } ) = loadraw ( fid, data.( fields { findex } ) );
    end
    
    % Closes the binary file.
    fclose ( fid );
end


function trialdata = loadraw ( fid, trialdata )

% Iterates along trials.
for tindex = 1: numel ( trialdata.trial )
    
    % Gets the metadata.
    meta   = trialdata.trial { tindex };
    
    % Gets the offset.
    offset = meta (1);
    
    % Gets the type of data.
    type   = matclass2class ( meta (2) );
    
    % Gets the size of the data.
    tsize  = meta ( 3: end );
    
    % Applies the offset.
    fseek ( fid, offset, 'bof' );
    
    % Reads the data from the file.
    trialdata.trial { tindex } = fread ( fid, tsize, sprintf ( '%s=>%s', type, type ) );
end


function type = matclass2class ( type )

% Value  Symbol        MAT-File Data Type
%     1  miINT8        8 bit, signed
%     2  miUINT8       8 bit, unsigned
%     3  miINT16       16-bit, signed
%     4  miUINT16      16-bit, unsigned
%     5  miINT32       32-bit, signed
%     6  miUINT32      32-bit, unsigned
%     7  miSINGLE      IEEE®
%     8  --            Reserved
%     9  miDOUBLE      IEEE 754 double format
%    10  --            Reserved
%    11  --            Reserved
%    12  miINT64       64-bit, signed
%    13  miUINT64      64-bit, unsigned
%    14  miMATRIX      MATLAB array
%    15  miCOMPRESSED  Compressed Data
%    16  miUTF8        Unicode UTF-8 Encoded Character Data
%    17  miUTF16       Unicode UTF-16 Encoded Character Data
%    18  miUTF32       Unicode UTF-32 Encoded Character Data

switch type
    case  1, type =   'int8';
    case  2, type =  'uint8';
    case  3, type =  'int16';
    case  4, type = 'uint16';
    case  5, type =  'int32';
    case  6, type = 'uint32';
    case 12, type =  'int64';
    case 13, type = 'uint64';
    case  7, type = 'single';
    case  9, type = 'double';
    otherwise
        error ( 'Unaccepted data type.' )
end
