function [ ob, oa ] = my_matchstr ( a, b )

% Makes sure that the input are cells of strings.
if isempty ( a ), a = {};
elseif ~iscell ( a ), a = cellstr ( a );
end
if isempty ( b ), b = {};
elseif ~iscell ( b ), b = cellstr ( b );
end

% Gets the number of elements in a.
na = numel ( a );

% Reserves memory for the output.
oa = nan ( size  ( a ) );
ob = nan ( size  ( b ) );

% Converts the arrays to numeric identifiers.
[ ~, ~, idx ] = unique ( cat ( 1, a (:), b (:) ) );
a  = idx ( 1: na );
b  = idx ( na + 1: end );

% Gets only the common identifiers.
c  = intersect ( a, b );

% Locates the position of the elements in one array in the other.
for cindex = 1: numel ( c )
    oa ( a == c ( cindex ) ) = find ( b == c ( cindex ), 1 );
    ob ( b == c ( cindex ) ) = find ( a == c ( cindex ), 1 );
end