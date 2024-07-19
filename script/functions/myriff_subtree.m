function rifftree = myriff_subtree ( rifftree, varargin )

% If no branch defined returns the current tree.
if nargin == 1
    return
end

% Gets the label fo the first branch.
blabel   = varargin {1};

% Looks for the branch in the tree.
bindex   = find ( strcmp ( strtrim ( { rifftree.children.label } ), blabel ) );

% If more than one match returns only the first one.
if numel ( bindex ) > 1
    warning ( 'Several hits for %s, returning only the first result.', blabel );
    bindex = bindex (1);
end

% Keeps only the desired branch.
rifftree = rifftree.children ( bindex );

% Iterates through the next branch, if requested.
rifftree = myriff_subtree ( rifftree, varargin { 2: end } );
