function tag = myfiff_find_tag ( fid, node, target )

% Ensures that it is only one node.
node = node (1);

% Looks for the requested kind of data.
index = find ( [ node.dir.kind ] == target, 1 );
if index
    tag = fiff_read_tag ( fid, node.dir ( index ).pos );
else
    tag = [];
end
