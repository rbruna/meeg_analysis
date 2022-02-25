function myft_save ( filename, data )

% Generates the MAT file and binary file filanames.
basefile = regexprep ( filename, '(.mat$)', '' );
matfile  = sprintf ( '%s.mat', basefile );
binfile  = sprintf ( '%s.dat', basefile );

% If the input is not a struct raises an error.
if ~isstruct ( data )
    error ( 'Unknown data type.' );
end

% Checks if the data itself is FieldTrip raw data.
if ft_datatype ( data, 'raw' )
    
    % Inserts the variable in a structure.
    data = struct ( inputname (2), data );
end

% If the data is less than 1 GB in memory saves it and exits.
datainfo = whos ( 'data' );
if datainfo.bytes <= 1.8 * 1024 * 1024 * 1024
    save ( '-v6', matfile, '-struct', 'data' )
    return
end


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

% Saves the trials in the binary file, if any.
if numel ( fields )
    
    % Opens the binary file to write.
    fid = fopen ( binfile, 'Wb', 'ieee-le' );
    
    % Saves the trials in the binary file.
    for findex = 1: numel ( fields )
        data.( fields { findex } ) = saveraw ( fid, data.( fields { findex } ) );
    end
    
    % Closes the binary file.
    fclose ( fid );
    
    % Saves the MAT file.
    save ( '-v6', matfile, '-struct', 'data' )
end


function trialdata = saveraw ( fid, trialdata )

% Iterates along trials.
for tindex = 1: numel ( trialdata.trial )
    
    % Gets the data.
    data   = trialdata.trial { tindex };
    
    % Gets the offset.
    offset = ftell ( fid );
    
    % Gets the type of data for the current trial.
    ttype  = class2matclass ( data );
    
    % Gets the size of the data.
    tsize  = size ( data );
    
    % Writes the data to the file.
    fwrite ( fid, data, class ( data ) );
    
    % Replaces the data for its metadata.
    trialdata.trial { tindex } = cat ( 2, offset, ttype, tsize );
end


function type = class2matclass ( data )

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

switch class ( data )
    case   'int8', type =  1;
    case  'uint8', type =  2;
    case  'int16', type =  3;
    case 'uint16', type =  4;
    case  'int32', type =  5;
    case 'uint32', type =  6;
    case  'int64', type = 12;
    case 'uint64', type = 13;
    case 'single', type =  7;
    case 'double', type =  9;
    otherwise
        error ( 'Unaccepted data type.' )
end
