function tdpot = myom_asrctdpot ( tdpot, dippos, tpos, gint, pH, vH )

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


% Gets the three mid-points for each trinagle.
mpos1  = ( tpos ( 2, :, : ) + tpos ( 3, :, : ) ) / 2;
mpos2  = ( tpos ( 1, :, : ) + tpos ( 3, :, : ) ) / 2;
mpos3  = ( tpos ( 1, :, : ) + tpos ( 2, :, : ) ) / 2;

% Subdivides the triangles in four sub-triangles.
tpos1  = cat ( 1, tpos ( 1, :, : ), mpos3, mpos2 );
tpos2  = cat ( 1, tpos ( 2, :, : ), mpos1, mpos3 );
tpos3  = cat ( 1, tpos ( 3, :, : ), mpos2, mpos1 );
tpos4  = cat ( 1, mpos3, mpos1, mpos2 );


% Calculates the gradient of the potential at each sub-triangle.
tdpot1 = myom_srctdpot ( dippos, tpos1, gint, pH, vH );
tdpot2 = myom_srctdpot ( dippos, tpos2, gint, pH, vH );
tdpot3 = myom_srctdpot ( dippos, tpos3, gint, pH, vH );
tdpot4 = myom_srctdpot ( dippos, tpos4, gint, pH, vH );

% Combines the sub-triangles.
tdpota = tdpot1 + tdpot2 + tdpot3 + tdpot4;


% Calculates the relative error of the non-adaptative formulation.
dist   = sqrt ( sum ( ( tdpot - tdpota ) .^ 2, 3 ) );
err    = dist ./ sqrt ( sum ( tdpot .^ 2, 3 ) );

% % Updates the calculated potential with the improved version.
% tdpot   = tdpota;


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
    tdpot1d = myom_asrctdpot ( tdpot1 ( tindex, sindex, : ), dippos ( dindex, : ), tpos1 ( :, tindex, : ), gint, pH ( tindex, :, : ), vH ( tindex, :, : ) );
    tdpot2d = myom_asrctdpot ( tdpot2 ( tindex, sindex, : ), dippos ( dindex, : ), tpos2 ( :, tindex, : ), gint, pH ( tindex, :, : ), vH ( tindex, :, : ) );
    tdpot3d = myom_asrctdpot ( tdpot3 ( tindex, sindex, : ), dippos ( dindex, : ), tpos3 ( :, tindex, : ), gint, pH ( tindex, :, : ), vH ( tindex, :, : ) );
    tdpot4d = myom_asrctdpot ( tdpot4 ( tindex, sindex, : ), dippos ( dindex, : ), tpos4 ( :, tindex, : ), gint, pH ( tindex, :, : ), vH ( tindex, :, : ) );
    
    % Updates the calculated potential.
    tdpota ( tindex, sindex, : ) = tdpot1d + tdpot2d + tdpot3d + tdpot4d;
end

% Updates the values with large errors.
err = repmat ( err, 1, 1, 3 );
tdpot ( err > tol ) = tdpota ( err > tol );
