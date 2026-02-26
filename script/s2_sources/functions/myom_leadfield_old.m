function leadfield = myom_leadfield ( headmodel, grid, sens )

% Based on FiedTrip functions:
% * ft_leadfield_openmeeg by Daniel D.E. Wong, Sarang S. Dalal
%
% Based on the OpenMEEG functions:
% * openmeeg_dsm by Alexandre Gramfort
% * openmeeg_megm by Emmanuel Olivi


% Adds OpenMEEG to the path.
ft_hastoolbox ( 'openmeeg', 1, 1 );

% Checks the OpenMEEG installation.
myom_checkom

% Checks the geometrical definition of the head model.
headmodel = myom_check_headmodel ( headmodel );


% Sets the temporal base name.
basename  = tempname;


% Gets the sensors type.
ismeg = isfield ( sens, 'coilpos' ) &&  isfield ( sens, 'coilori' );
iseeg = isfield ( sens, 'elecpos' );

% Makes sure that the sensors are correctly identified.
if ~xor ( ismeg, iseeg ), error ( 'The sensor type could not be identified as EEG or MEG. Aborting.\n' ); end



% Expands the head and hm\dsm matrices, if required.
if iseeg && ~ismeg
    headmodel = myom_untrimmat ( headmodel );
end

% If no headmodel matrix, calculates it using myom_headmodel.
if ~isfield ( headmodel, 'hm' ) && ~isfield ( headmodel, 'ihm' ) && ~isfield ( headmodel, 'hm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Head model matrix not present in the data. Calculating it.\n' ); end
    
    headmodel = myom_headmodel ( headmodel, true );
end

% If no sources matrix, calculates it using myom_sourcematrix.
if ~isfield ( headmodel, 'dsm' ) && ~isfield ( headmodel, 'hm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Source matrix not present in the data. Calculating it.\n' ); end
    
    headmodel = myom_sourcematrix ( headmodel, grid );
end

% If no hm\dsm matrix, calculates it.
if ~isfield ( headmodel, 'hm_dsm' )
    
    if myom_verbosity, fprintf ( 1, 'Source matrix not present in the data. Calculating it.\n' ); end
    
    headmodel.hm_dsm = headmodel.hm \ headmodel.dsm;
    
    % Deletes the head model and sources matrices to save memory.
    headmodel = rmfield ( headmodel, { 'hm' 'dsm' } );
end


% Writes the dipole file.
myom_write_dipoles ( basename, grid )

% Writes the geometry files.
myom_write_geometry ( basename, headmodel )


% Writes the sensors position.
if ismeg
    
    % Writes the gradiometers file.
    myom_save_full ( cat ( 2, sens.coilpos, sens.coilori ), sprintf ( '%s_sens.txt', basename ), 'ascii' );
end
if iseeg
    
    % Writes the electrodes file.
    myom_save_full ( sens.elecpos, sprintf ( '%s_sens.txt', basename ), 'ascii' );
end


if ismeg
    
    % Calculates the dipoles to MEG matrix.
    if myom_verbosity
        status = system ( sprintf ( 'om_assemble -ds2mm "%s_dip.bin" "%s_sens.txt" "%s_s2mm.mat"\n', basename, basename, basename ) );
    else
        [ status, output ] = system ( sprintf ( 'om_assemble -ds2mm "%s_dip.bin" "%s_sens.txt" "%s_s2mm.mat"\n', basename, basename, basename ) );
    end
    
    % Checks for the completion of the execution.
    if status ~= 0
        if myom_verbosity == 0, fprintf ( 1, '%s', output ); end
        fprintf ( 2, 'OpenMEEG program ''om_assemble'' exited with error code %i.\n', status );
        
        % Removes all the temporal files and exits.
        delete ( sprintf ( '%s*', basename ) );
        return
    end
    
    % Calculates the head surface to MEG matrix.
    if myom_verbosity
        status = system ( sprintf ( 'om_assemble -h2mm "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2mm.mat"\n', basename, basename, basename, basename ) );
    else
        [ status, output ] = system ( sprintf ( 'om_assemble -h2mm "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2mm.mat"\n', basename, basename, basename, basename ) );
    end
    
    % Checks for the completion of the execution.
    if status ~= 0
        if myom_verbosity == 0, fprintf ( 1, '%s', output ); end
        fprintf ( 2, 'OpenMEEG program ''om_assemble'' exited with error code %i.\n', status );
        
        % Removes all the temporal files and exits.
        delete ( sprintf ( '%s*', basename ) );
        return
    end
    
    % Recovers the calculated model matrices.
    headmodel.s2mm = importdata ( sprintf ( '%s_s2mm.mat', basename ) );
    headmodel.h2mm = importdata ( sprintf ( '%s_h2mm.mat', basename ) );
    
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.s2mm + headmodel.h2mm * headmodel.hm_dsm;
end

if iseeg
    
    % Calculates the head surface to EEG matrix.
    if myom_verbosity
        status = system ( sprintf ( 'om_assemble -h2em "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2em.mat"\n', basename, basename, basename, basename ) );
    else
        [ status, output ] = system ( sprintf ( 'om_assemble -h2em "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2em.mat"\n', basename, basename, basename, basename ) );
    end
    
    % Checks for the completion of the execution.
    if status ~= 0
        if myom_verbosity == 0, fprintf ( 1, '%s', output ); end
        fprintf ( 2, 'OpenMEEG program ''om_assemble'' exited with error code %i.\n', status );
        
        % Removes all the temporal files and exits.
        delete ( sprintf ( '%s*', basename ) );
        return
    end
    
    % Recovers the calculated model matrix.
    headmodel.h2em = importdata ( sprintf ( '%s_h2em.mat', basename ) );
    
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2em * double ( headmodel.hm_dsm );
end

% Removes all the temporal files.
delete ( sprintf ( '%s*', basename ) );


% % Applies the coil/electrode to channel transformation.
% if isfield ( sens, 'tra' )
%     leadfield = sens.tra * leadfield;
% end
