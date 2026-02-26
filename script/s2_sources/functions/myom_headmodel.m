function headmodel = myom_headmodel ( headmodel )
% Based on FiedTrip functions:
% * ft_headmodel_openmeeg


% Adds OpenMEEG to the path.
ft_hastoolbox ( 'openmeeg', 1, 1 );

% Checks the OpenMEEG installation.
myom_checkom

% Checks the geometrical definition of the head model.
headmodel = myom_check_headmodel ( headmodel );


% Sets the temporal base name.
basename = tempname;

% Writes the geometry files.
myom_write_geometry ( basename, headmodel )


% Calculates the head matrix.
if myom_verbosity
    status = system ( sprintf ( 'om_assemble -hm "%s.geom" "%s.cond" "%s_hm.mat"\n', basename, basename, basename ) );
else
    [ status, output ] = system ( sprintf ( 'om_assemble -hm "%s.geom" "%s.cond" "%s_hm.mat"\n', basename, basename, basename ) );
end

% Checks for the completion of the execution.
if status ~= 0
    if myom_verbosity == 0, fprintf ( 1, '%s', output ); end
    fprintf ( 2, 'OpenMEEG program ''om_assemble'' exited with error code %i.\n', status );
    
    % Removes all the temporal files and exits.
    delete ( sprintf ( '%s*', basename ) );
    return
end

% Recovers the calculated head model matrix.
headmodel.hm = importdata ( sprintf ( '%s_hm.mat', basename ) );

% Removes all the temporal files.
delete ( sprintf ( '%s*', basename ) );
