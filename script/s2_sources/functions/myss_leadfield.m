function leadfield = myss_leadfield ( grid, headmodel, sens )
% Magnetic field of N dipoles using spherical harmonic expansion.

% Based on FiedTrip functions:
% * meg_ini by Guido Nolte
% * meg_forward by Guido Nolte


% Calculates the model parameters, if needed.
if ~isfield ( headmodel, 'params' )
    headmodel = myss_headmodel ( headmodel, sens );
end

% Gets the parameters.
order   = headmodel.params.order;
center  = headmodel.params.center;
sensors = headmodel.params.sensors;



% If there is an 'inside' field in the grid, takes only those grid points.
if isfield ( grid, 'inside' )
    dipole.pos = grid.pos ( grid.inside, : );
else
    dipole.pos = grid.pos;
end

% If no original dipole orientation, uses the identity matrix.
if isfield ( grid, 'ori' )
    dipole.ori = grid.ori;
else
    dipole.ori = eye (3);
end

% Gets the number of dipoles and orientations.
ndipoles = size ( dipole.pos, 1 );
noris    = size ( dipole.ori, 1 );

% Matches the dipoles and their orientation.
if noris == 3 && det ( dipole.ori ) - 1 < 1e-6
    
    % The orientation must be applied to each dipole.
    dipole.pos = kron ( dipole.pos, ones ( 3, 1 ) );
    dipole.ori = kron ( ones ( ndipoles, 1 ), dipole.ori );
    
elseif noris == ndipoles
    
    % Each dipole has its orientation. Nothing to do.
    
elseif noris == ndipoles * 3
    
    % Each dipole has 3 orientations.
    dipole.pos = kron ( dipole.pos, ones ( 3, 1 ) );
    
else
    error ( 'Imposible to match dipoles and orientations.' );
end

% Composes the dipoles matrix.
dipoles  = cat ( 2, dipole.pos, dipole.ori );

% Data must be double precission to avoid numeric inestabilities.
dipoles  = double ( dipoles );

% Calculates the initial leadfield and the correction coefficents.
leadfield = getfield_sphere ( dipoles, sensors, center );
corrcoef  = headmodel.params.coeff_sens;

% Corrects the leadfield using the reference sensors.
if isfield ( headmodel.params, 'coeff_ref' )
    leadfield = leadfield - getfield_sphere ( dipoles, refsens, center );
    corrcoef  = corrcoef  - headmodel.params.coeff_ref;
end

% Adds extra MEG channels.
if isfield ( headmodel.params, 'coeff_weights' )
    leadfield = leadfield + headmodel.params.weights * getfield_sphere ( dipoles, extrasens, center );
    corrcoef  = corrcoef  + headmodel.params.coeff_weights * headmodel.params.weights';
end

% Corrects using spherical harmonics, if requested.
if order > 0
    leadfield = leadfield + getfield_corr ( dipoles, corrcoef, center, order );
end


% % Applies the coil to channel transformation.
% if isfield ( sens, 'tra' )
%     leadfield = sens.tra * leadfield;
% end


function leadfield = getfield_sphere ( source, sens, center )

% Sets the center of the surface as origin.
dippos  = bsxfun ( @minus, source ( :, 1: 3 ), center );
dipori  = source ( :, 4: 6 );
coilpos = bsxfun ( @minus, sens ( :, 1: 3 ), center );
coilori = sens ( :, 4: 6 );

%spherical
bt = myss_aux_leadsphere_chans ( dippos', coilpos', coilori');

leadfield = squeeze ( dot3d ( dipori', bt ) )';


function leadfield = getfield_corr ( source, coeffs, center, order )

% Sets the center of the surface as origin.
dippos = bsxfun ( @minus, source ( :, 1: 3 ), center );
dipori = source ( :, 4: 6 );

% Applies the correction.
if order > 0
    scale = 10;
    [ ~, gradbas ] = myss_aux_legs ( dippos, dipori, order, scale );
    nbasis = ( order + 1 ) ^ 2 - 1;
    coeffs = coeffs ( 1: nbasis, : );
    leadfield = -( gradbas * coeffs )';
end


function dot = dot3d ( vector1, vector2 )

dot = sum ( bsxfun ( @times, vector1, vector2 ) );
