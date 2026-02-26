function headmodel = myom_addelec ( headmodel, sens )

% Based on FiedTrip functions:
% * ft_leadfield_openmeeg by Daniel D.E. Wong, Sarang S. Dalal
%
% Based on the OpenMEEG functions:
% * openmeeg_dsm by Alexandre Gramfort
% * openmeeg_megm by Emmanuel Olivi


% Gets the sensors type.
ismeg = isfield ( sens, 'coilpos' ) &&  isfield ( sens, 'coilori' );
iseeg = isfield ( sens, 'elecpos' );

% Checks that the sensors are MEG.
if ~iseeg, error ( 'This function can only by used with an EEG sensor definition.' ); end

% Gets sure that the sensors are correctly identified.
if ~xor ( ismeg, iseeg ), error ( 'The sensor type could not be identified as EEG or MEG. Aborting.\n' ); end


% Adds OpenMEEG to the path.
ft_hastoolbox ( 'openmeeg', 1, 1 );

% Checks the OpenMEEG installation.
myom_checkom

% Checks the geometrical definition of the head model.
headmodel = myom_check_headmodel ( headmodel );


% Checks if the sensor definition has changed.
if ~isfield ( headmodel, 'h2em' ) || ...
    ~isfield ( headmodel, 'elec' ) || ...
    ~isequal ( sens, headmodel.elec )
    
    % Calculates the head surface to electrodes matrix.
    headmodel.h2em = myom_head2elec ( headmodel, sens );
    
    % Stores the sensor definition.
    headmodel.elec = sens;

%     
%     % Sets the temporal base name.
%     basename  = tempname;
%     
%     % Writes the geometry files.
%     myom_write_geometry ( basename, headmodel )
%     
%     % Writes the electrodes file.
%     myom_save_full ( sens.elecpos, sprintf ( '%s_sens.txt', basename ), 'ascii' );
%     
%     
%     % Calculates the head surface to electrodes matrix using OpenMEEG.
%     if myom_verbosity
%         status = system ( sprintf ( 'om_assemble -h2em "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2em.mat"\n', basename, basename, basename, basename ) );
%     else
%         [ status, output ] = system ( sprintf ( 'om_assemble -h2em "%s.geom" "%s.cond" "%s_sens.txt" "%s_h2em.mat"\n', basename, basename, basename, basename ) );
%     end
%     
%     % Checks for the completion of the execution.
%     if status ~= 0
%         if myom_verbosity == 0, fprintf ( 1, '%s', output ); end
%         fprintf ( 2, 'OpenMEEG program ''om_assemble'' exited with error code %i.\n', status );
%         
%         % Removes all the temporal files and exits.
%         delete ( sprintf ( '%s*', basename ) );
%         return
%     end
%     
%     % Recovers the calculated model matrix.
%     headmodel.h2em = importdata ( sprintf ( '%s_h2em.mat', basename ) );
%     
%     % Stores the sensor definition.
%     headmodel.elec = sens;
% 
%     % Removes all the temporal files.
%     delete ( sprintf ( '%s*', basename ) );
end
