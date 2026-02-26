function tpot = myom_asrctpot_old ( tpot, dippos, tpos, gint, cond )

% The limit of recursion is 10.
stack = dbstack;
if sum ( strcmp ( { stack.name }, mfilename ) ) > 10
    return
end

% Defines the tolerance.
tol    = 1e-3;


% Gets the three medi-points for each trinagle.
mpos1  = ( tpos ( 2, :, : ) + tpos ( 3, :, : ) ) / 2;
mpos2  = ( tpos ( 1, :, : ) + tpos ( 3, :, : ) ) / 2;
mpos3  = ( tpos ( 1, :, : ) + tpos ( 2, :, : ) ) / 2;

% Subdivides the triangles in four sub-triangles.
tpos1  = cat ( 1, tpos ( 1, :, : ), mpos3, mpos2 );
tpos2  = cat ( 1, tpos ( 2, :, : ), mpos1, mpos3 );
tpos3  = cat ( 1, tpos ( 3, :, : ), mpos2, mpos1 );
tpos4  = cat ( 1, mpos3, mpos1, mpos2 );


% Calculates the potential at each sub-triangle.
tpot1  = myom_srctpot ( dippos, tpos1, gint, cond );
tpot2  = myom_srctpot ( dippos, tpos2, gint, cond );
tpot3  = myom_srctpot ( dippos, tpos3, gint, cond );
tpot4  = myom_srctpot ( dippos, tpos4, gint, cond );

% Combines the sub-triangles.
tpota  = tpot1 + tpot2 + tpot3 + tpot4;


% Calculates the relative error of the non-adaptative formulation.
dist   = abs ( tpot - tpota );
err    = dist ./ abs ( tpot );

% % Updates the calculated potential with the improved version.
% tpot   = tpota;


% If the error is above the tolerance continues iterating.
if any ( err (:) > tol )
    
    % Gets the list of dipoles and triangles to fix.
    tindex = any ( err > tol, 2 );
    oindex = any ( err > tol, 1 );
    dindex = any ( reshape ( oindex, 3, [] ), 1 );
    dindex = repmat ( dindex, 3, 1 );
    
    % Applies the adaptative iteration.
    tpot1  = myom_asrctpot_old ( tpot1 ( tindex, dindex ), dippos ( dindex ( 1, : ), : ), tpos1 ( :, tindex, : ), gint, cond );
    tpot2  = myom_asrctpot_old ( tpot2 ( tindex, dindex ), dippos ( dindex ( 1, : ), : ), tpos2 ( :, tindex, : ), gint, cond );
    tpot3  = myom_asrctpot_old ( tpot3 ( tindex, dindex ), dippos ( dindex ( 1, : ), : ), tpos3 ( :, tindex, : ), gint, cond );
    tpot4  = myom_asrctpot_old ( tpot4 ( tindex, dindex ), dippos ( dindex ( 1, : ), : ), tpos4 ( :, tindex, : ), gint, cond );
    
    % Updates the value of the potential.
    tpota ( tindex, dindex ) = tpot1 + tpot2 + tpot3 + tpot4;
    tpot ( err > tol ) = tpota ( err > tol );
end
