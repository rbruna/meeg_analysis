function block = myfiff_read_block ( source, tree, name )

% Based on MNE-Python functions:
% * meas_info.py/read_meas_info by Eric Larson

% Loads the FIFF dictionary.
dict  = myfiff_dictionary;
entry = dict ( strcmp ( { dict.name }, name ) );

% Initializes the output.
block = struct;


% If the block not in the the dictionary exits.
if isempty ( entry )
    return
end

% Opens the file, if needed.
if isempty ( tree )
    [ fid, tree ] = fiff_open ( source );
else
    fid = source;
end


% Looks for the desired block.
fiff_blocks = fiff_dir_tree_find ( tree, entry.kind );

% Goes through each hit.
for bindex = 1: numel ( fiff_blocks )
    
    % Gets the current block.
    fiff_block = fiff_blocks ( bindex );
    
    % Goes through each tag.
    for tindex = 1: fiff_block.nent
        kind = fiff_block.dir ( tindex ).kind;
        pos  = fiff_block.dir ( tindex ).pos;
        
        % Reads known tags.
        if any ( [ entry.tag.kind ] == kind )
            name = entry.tag ( [ entry.tag.kind ] == kind ).name;
            tag  = fiff_read_tag ( fid, pos );
            
            if numel ( block ) < bindex || ~isfield ( block ( bindex ), name )
                block ( bindex ).( name ) = [];
            end
            
            % Stores the tag content.
            block ( bindex ).( name ) = cat ( 1, block ( bindex ).( name ), tag.data );
        end
    end
    
    % Goes through each child block.
    for cindex = 1: numel ( entry.child )
        name = entry.child ( cindex ).name;
        block ( bindex ).( name ) = myfiff_read_block ( fid, fiff_block, name );
    end
end


% Closes the file, if needed.
if ~isequal ( fid, source )
    fclose ( fid );
end
