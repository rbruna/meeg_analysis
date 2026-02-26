function tpot = myom_asrctpot ( tpot, dippos, tpos, gint, cond )

% The limit of recursion is 10.
stack = dbstack;
if sum ( strcmp ( { stack.name }, mfilename ) ) > 10
    return
end

% Defines the tolerance.
tol    = 1e-3;


% Gets the size of the problem.
ntri   = size ( tpos, 2 );
ndip   = size ( dippos, 1 );


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


% Identifies the bad dipoles.
errdip = reshape ( err, ntri, 3, ndip );
errdip = any ( errdip > tol, 2 );
errdip = reshape ( errdip, ntri, ndip );

% Goes through ech dipole.
for dindex = 1: ndip
    
    % Lists the trinagles with large errors.
    tindex = errdip ( :, dindex );
    
    % If no large errors, continue.
    if ~any ( tindex ), continue, end
    
    % Gets the position of the three dipoles.
    sindex = ( dindex - 1 ) * 3 + ( 1: 3 );
    
    % Applies the adaptive integration where the error is large.
    tpot1d  = myom_asrctpot ( tpot1 ( tindex, sindex ), dippos ( dindex, : ), tpos1 ( :, tindex, : ), gint, cond );
    tpot2d  = myom_asrctpot ( tpot2 ( tindex, sindex ), dippos ( dindex, : ), tpos2 ( :, tindex, : ), gint, cond );
    tpot3d  = myom_asrctpot ( tpot3 ( tindex, sindex ), dippos ( dindex, : ), tpos3 ( :, tindex, : ), gint, cond );
    tpot4d  = myom_asrctpot ( tpot4 ( tindex, sindex ), dippos ( dindex, : ), tpos4 ( :, tindex, : ), gint, cond );
    
    % Stores the calculated potential.
    tpota ( tindex, sindex ) = tpot1d + tpot2d + tpot3d + tpot4d;
end

% Updates the values with large errors.
tpot ( err > tol ) = tpota ( err > tol );
