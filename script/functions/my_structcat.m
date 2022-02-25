function structure = my_structcat ( varargin )

% Checks if the first input is the dimension.
if isnumeric ( varargin {1} ) && isscalar ( varargin {1} )
    dimension = varargin {1};
    structure = varargin ( 2: end );
else
    dimension = 1;
    structure = varargin;
end

% Checks the inputs.
if ~all ( cellfun ( @isstruct, structure ) )
    error ( 'Wrong data type.' )
end

% Gets the total number of fields.
fields    = cellfun ( @fieldnames, structure, 'UniformOutput', false );
fields    = unique ( cat ( 1, fields {:} ) );
fields    = repmat ( { fields }, size ( structure ) );

% Expands the fields of all the inputs.
structure = cellfun ( @expandfield, structure, fields, 'UniformOutput', false );

% Concatenates all the structures in the original order.
structure = cat ( dimension, structure {:} );


function structure = expandfield ( structure, fields )

% Gets only the new fields.
fields = setdiff ( fields, fieldnames ( structure ) );

% If all the fields are present does nothing.
if isempty ( fields )
    return
end

% Adds each new field.
for findex = 1: numel ( fields )
    structure (1).( fields { findex } ) = [];
end
