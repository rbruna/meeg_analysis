function tdpot = myom_asrctdpot_old ( tdpot, dippos, tpos, gint, pH, vH )

% The limit of recursion is 10.
stack = dbstack;
if sum ( strcmp ( { stack.name }, mfilename ) ) > 10
    return
end

% Defines the tolerance.
tol    = 1e-3;


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


% If the error is above the tolerance continues iterating.
if any ( err (:) > tol )
    
    % Gets the list of dipoles and triangles to fix.
    tindex = any ( err > tol, 2 );
    oindex = any ( err > tol, 1 );
    dindex = any ( reshape ( oindex, 3, [] ), 1 );
    dindex = repmat ( dindex, 3, 1 );
    
    pH     = pH ( tindex, :, : );
    vH     = vH ( tindex, :, : );
    
    % Applies the adaptative iteration.
    tdpot1 = myom_asrctdpot_old ( tdpot1 ( tindex, dindex, : ), dippos ( dindex ( 1, : ), : ), tpos1 ( :, tindex, : ), gint, pH, vH );
    tdpot2 = myom_asrctdpot_old ( tdpot2 ( tindex, dindex, : ), dippos ( dindex ( 1, : ), : ), tpos2 ( :, tindex, : ), gint, pH, vH );
    tdpot3 = myom_asrctdpot_old ( tdpot3 ( tindex, dindex, : ), dippos ( dindex ( 1, : ), : ), tpos3 ( :, tindex, : ), gint, pH, vH );
    tdpot4 = myom_asrctdpot_old ( tdpot4 ( tindex, dindex, : ), dippos ( dindex ( 1, : ), : ), tpos4 ( :, tindex, : ), gint, pH, vH );
    
    err = repmat ( err, 1, 1, 3 );
    
    % Updates the value of the potential.
    tdpota ( tindex, dindex, : ) = tdpot1 + tdpot2 + tdpot3 + tdpot4;
    tdpot ( err > tol ) = tdpota ( err > tol );
end
