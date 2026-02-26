function myom_write_dipoles ( basename, grid )

% Sanitizes the grid.
grid     = my_fixgrid ( grid );


% Takes only the required dipoles.
dipole.pos = grid.pos ( grid.inside, : );

% Takes, if required, the active orientations.
if size ( grid.ori, 1 ) == size ( grid.pos, 1 )
    dipole.ori = grid.ori ( grid.inside );
else
    dipole.ori = grid.ori;
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

% Triplicates the dipole positions, one repetition for each orientation.
dipoles  = cat ( 2, dipole.pos, dipole.ori );

% Writes the dipole file.
% om_save_full ( dipoles, sprintf ( '%s_dip.bin', basename ) );
fid = fopen ( sprintf ( '%s.dip', basename ), 'wt' );
fprintf ( fid, '%+.16e %+.16e %+.16e %+.16e %+.16e %+.16e\n', dipoles' );
fclose ( fid );
