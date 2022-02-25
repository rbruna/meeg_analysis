function rawinfo = mymff_read_rawinfo ( filename )

% Based on FieldTrip functions:
% * read_mff_block


% Opens the file to read.
fid = fopen ( filename, 'rb', 'ieee-le' );

% First block cannot be of type 0 (reuse previous block's header).
heasdertype = fread ( fid, 1, 'int32' );
if heasdertype == 0, error ( 'Corrupted data file ''%s''', filename ); end
fseek ( fid, 0, 'bof' );

% Initializes the block index.
bindex = 0;

% Iterates until the end of the file.
while true
    
    % Updates the block index.
    bindex           = bindex + 1;
    
    % Reads the header type.
    block            = [];
    block.blockstart = ftell ( fid );
    block.headertype = fread ( fid, 1, 'int32' );
    
    % If no more data exits.
    if feof ( fid ), break, end
    
    % If header type 0 reuses the previous header.
    if block.headertype == 0
        thisblock        = block;
        block = rawinfo ( bindex - 1 );
        block.blockstart = thisblock.blockstart;
        block.headertype = 0;
        block.headersize = 4;
        
    % Otherwise reads the nexheader.
    else
        block.headersize = fread ( fid, 1, 'int32' );
        block.datasize   = fread ( fid, 1, 'int32' );
        block.nsignals   = fread ( fid, 1, 'int32' );
        block.nsamples   = [];
        
        % Reads the offset for each channel.
        block.offset     = fread ( fid, block.nsignals, 'int32' );
        
        % Reads the precission (in bits) and the sampling rate of the channel.
        block.fsample    = fread ( fid, block.nsignals, 'int32' );
        block.depth      = bitand ( block.fsample, 255, 'uint32' );
        block.fsample    = bitshift ( block.fsample, -8 );
        
        % Calculates the number of samples.
        block.nsamples   = diff ( cat ( 1, block.offset, block.datasize ) ) .* ( 8 ./ block.depth );
        
        % Reads the optional header.
        block.optlength   = fread(fid, 1, 'int32');
        if block.optlength
            block.opthdr.EGItype  = fread(fid, 1, 'int32');
            block.opthdr.nblocks  = fread(fid, 1, 'int64');
            block.opthdr.nsamples = fread(fid, 1, 'int64');
            block.opthdr.nsignals = fread(fid, 1, 'int32');
        else
            block.opthdr = [];
        end
    end
    
    % Skips the data block.
    fseek ( fid, block.datasize, 'cof' );
    
    % Makes a rough estimation of the number of blocks.
    if bindex == 1
        current          = ftell ( fid );
        fseek ( fid, 0, 'eof' );
        filesize         = ftell ( fid );
        fseek ( fid, current, 'bof' );
        
        % Reserves memory for the structure.
        rawinfo          = block ( [] );
        rawinfo ( ceil ( filesize / current ) ).headertype = [];
    end
    
    % Stores the header.
    rawinfo ( bindex ) = block;
end
