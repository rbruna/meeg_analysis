function tree = myriff_read ( filename )


% Opens the file to read.
fid  = fopen ( filename, 'rb', 'ieee-le' );

% Gets the total file length.
info = dir ( filename );
flen = info.bytes;

% Reads the magic number.
mnum = fread ( fid, [ 1 4 ], 'char=>char' );

% Defines the length of the pointers (chuck size marker).
switch mnum
    case 'RIFF'
        plen = 32;
    case 'RF64'
        plen = 64;
    otherwise, error ( 'Not a RIFF file.' );
end

% Gets the total data length.
dlen = fread ( fid, 1, sprintf ( 'bit%i', plen ) );

% If the data extends beyond the file rises an error.
if dlen + plen / 8 + 4 > flen
    error ( 'Data is incomplete or extends beyond the end of the file.' )
end


% Restarts the file cursor.
fseek ( fid, 0, 'bof' );

% Reads the RIFF tree from the file.
tree = read_riff_tree ( fid, plen );

% Closes the file.
fclose ( fid );



function tree = read_riff_tree ( fid, plen )

% Reads the label and length for the current chunk.
clab = fread ( fid, [ 1 4 ], 'char=>char' );
clen = fread ( fid, 1, sprintf ( 'bit%i', plen ) );
dpos = ftell ( fid );

% If the chunk is a list entry iterates over it.
if ismember ( clab, { 'RIFF' 'RF64' 'LIST' } )
    
    % Reads the block label.
    clab = fread ( fid, [ 1 4 ], 'char=>char' );
    clen = clen - 4;
    
    % Gets the current position of the pointer.
    cpos = ftell ( fid );
    
    % Initializes the data field.
    data = [];
    chil = cell (0);
    
    % Reads the subtree iteratively;
    while true
        
        % Checks if the chunk is completely read.
        if ftell ( fid ) >= cpos + clen
            break
        end
        
        % Reads the next children.
        chil { numel ( chil ) + 1 } = read_riff_tree ( fid, plen );
    end
    
    % Concatenates the children into a structure.
    chil = cat ( 1, chil {:} );
    
elseif ~feof ( fid )
    
    % Reads the data.
    data = fread ( fid, clen, 'uint8=>uint8' );
    
    % Reads the padding data, if required.
    fread ( fid, rem ( clen, 2 ), 'uint8=>uint8' );
    
    % Initializes the children structure.
    chil = [];
    
end


% Creates the tree structure.
tree.label    = clab;
tree.length   = clen;
tree.datapos  = dpos;
tree.data     = data;
tree.children = chil;
