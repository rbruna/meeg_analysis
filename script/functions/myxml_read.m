function tree = myxml_read ( document )

% Creates global variables for the CDATA and the comments.
global cds
global com

% Reads the document to memory.
fid = fopen ( document, 'r' );
dom = fread ( fid, [ 1 inf ], 'char=>char' );
fclose ( fid );

% First looks for CDATA.
cds = regexp ( dom, '<!\[CDATA\[(.*)\]\]>', 'tokens' );
dom = regexprep ( dom, '<!\[CDATA\[(.*)\]\]>', '<![CDATA[]]>' );

% Looks for comments.
com = regexp ( dom, '<!--(.*)-->', 'tokens' );
dom = regexprep ( dom, '<!--(.*)-->', '<!---->' );

tree = make_tree ( dom );



function tree = make_tree ( dom )

% Initializes the tree.
tree = struct;

if isempty ( strtrim ( dom ) )
    tree = strtrim ( dom );
end

% Iterates indefinitely.
while true
    
    % Gets the next DOM node.
    [ name, attr, ntree, dom ] = get_next ( dom );
    
    % If empty node (end of the DOM tree) exits.
    if isempty ( name ) && isempty ( ntree ), break, end
    
    % Adds the node to the tree.
    tree = add_node ( tree, name, ntree, attr );
end



function [ name, attr, tree, dom ] = get_next ( dom )

global cds
global com

% Looks for CDATA and comments.
tag = regexp ( strtrim ( dom ), '^<!\[CDATA\[\]\]>(.*)$', 'tokens' );
if ~isempty ( tag )
    name = [];
    attr = [];
    tree = cds {1} {1};
    dom  = tag {1} {1};
    cds (1) = [];
    return
end

tag = regexp ( strtrim ( dom ), '^<!---->(.*)$', 'tokens' );
if ~isempty ( tag )
    name = [];
    attr = [];
    tree = com {1} {1};
    dom  = tag {1} {1};
    com (1) = [];
    return
end


% Looks for text tags.
tag = regexp ( strtrim ( dom ), '^([^<]+)(.*)$', 'tokens' );
if ~isempty ( tag )
    name = [];
    attr = [];
    tree = tag {1} {1};
    dom  = tag {1} {2};
    return
end
    

% Looks for a standalone tags.
tag = regexp ( strtrim ( dom ), '^<\?\s*([a-zA-Z0-9_]*)\s*([^<]*)\s*\?>(.*)$', 'tokens' );
if ~isempty ( tag )
    name = tag {1} {1};
    attr = tag {1} {2};
    tree = struct;
    dom  = tag {1} {3};
    return
end

tag = regexp ( strtrim ( dom ), '^<!\s*([a-zA-Z0-9_]*)\s*([^<]*)>(.*)$', 'tokens' );
if ~isempty ( tag )
    name = tag {1} {1};
    attr = tag {1} {2};
    tree = struct;
    dom  = tag {1} {3};
    return
end

tag = regexp ( strtrim ( dom ), '^<\s*([a-zA-Z0-9_]*)\s*([^<]*)\s/>(.*)$', 'tokens' );
if ~isempty ( tag )
    name = tag {1} {1};
    attr = tag {1} {2};
    tree = struct;
    dom  = tag {1} {3};
    return
end


% Looks for opened-closed tags.
tag = regexp ( strtrim ( dom ), '^<\s*([a-zA-Z0-9_]+)\s*([^<]*)\s*>(.*)$', 'tokens' );
if ~isempty ( tag )
    name = tag {1} {1};
    attr = tag {1} {2};
    dom  = tag {1} {3};
    
    [ tree, dom ] = close_tag ( name, dom );
    return
end


% No element found.
name = [];
attr = [];
tree = [];



function [ tree, dom ] = close_tag ( name, dom )

% Gets the list of opened and closed tags.
tagopen  = regexp ( dom, sprintf ( '<\\s*%s(\\s[^<]*)*>',  name ) );
[ tagclose, tagclosed ] = regexp ( dom, sprintf ( '<\\s*/%s(\\s[^<]*)*>', name ), 'start', 'end' );

% Looks for the closing of the current tag.
tagopen  = cat ( 2, tagopen, inf );
tagindex = find ( tagclose < tagopen, 1 );

% Splits the DOM.
domin    = dom ( 1: tagclose ( tagindex ) - 1 );
dom      = dom ( tagclosed ( tagindex ) + 1: end );

% Navigates inside the element.
tree     = make_tree ( domin );



function tree = add_node ( tree, name, ntree, attr )

% If no name adds a text node.
if isempty ( name )
    tree = ntree;
    return
end

% Gets the new element index.
if isfield ( tree, name )
    eindex   = numel ( tree.( name ) ) + 1;
else
    eindex   = 1;
end

% If string, adds it.
if ischar ( ntree )
    tree.( name ) ( eindex ) = cellstr ( ntree );
    return
end

% Lists the new fields.
newfield = fieldnames ( ntree );

% Adds all the new fields.
for findex = 1: numel ( newfield )
    tree.( name ) ( eindex ).( newfield { findex } ) = ntree.( newfield { findex } );
end

% Adds the attributes.
tree.( name ) ( eindex ).xml_attr = attr;
