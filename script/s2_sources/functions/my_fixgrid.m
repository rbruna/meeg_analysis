function grid = my_fixgrid ( grid )

% Fix the absent or numerical 'inside' field.
if ~isfield ( grid, 'inside' ) || ~islogical ( grid.inside )
    
    % Initializes the 'inside' field to a logical array.
    inside = false ( size ( grid.pos ( :, 1 ) ) );
    
    % If numerical 'inside' field converts it to logical.
    if isfield ( grid, 'inside' )
        inside ( grid.inside ) = true;
        
    % Otherwise all the points are inside.
    else
        inside (:) = true;
    end
    
    % Stores the 'inside' field.
    grid.inside = inside;
end


% Fix the absent orientation field.
if ~isfield ( grid, 'ori' )
    
    % Sets the orientation as a set of three orthogonal vectors.
    grid.ori    = eye (3);
end
