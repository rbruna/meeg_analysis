function rawdata = myeep_read_raw ( filename, rifftree )


% Reads the RIFF file tree, if required.
if nargin < 2
    rifftree = myriff_read ( filename );
end


% Gets the raw data epoch information.
subtree  = myriff_subtree ( rifftree, 'raw3', 'ep' );
dummy    = typecast ( subtree.data, 'uint64' );

% Gets the number of epochs and the samples per epoch.
sepoch   = dummy (1);
epochs   = dummy ( 2: end );
nepoch   = numel ( dummy );


% Gets the raw data channel information.
subtree  = myriff_subtree ( rifftree, 'raw3', 'chan' );
dummy    = typecast ( subtree.data, 'uint16' );

% Gets the raw data channel order.
chorder  = dummy + 1;


% Gets the raw data itself.
subtree  = myriff_subtree ( rifftree, 'raw3', 'data' );
data     = subtree.data;


% Prepares the raw data information.
rawdata.epoch_count   = nepoch;
rawdata.epoch_length  = sepoch;
rawdata.epoch_start   = epochs;
rawdata.channel_order = chorder;
rawdata.data          = data;
