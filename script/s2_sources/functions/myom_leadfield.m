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


headmodel = myom_untrimmat ( headmodel );


% Gets the sensors type.
ismeg = isfield ( sens, 'coilpos' ) &&  isfield ( sens, 'coilori' );
iseeg = isfield ( sens, 'elecpos' );

% Makes sure that the sensors are correctly identified.
if ~xor ( ismeg, iseeg ), error ( 'The sensor type could not be identified as EEG or MEG. Aborting.\n' ); end


% Checks which matrices are available.
has_hm     = isfield ( headmodel, 'hm' );
has_ihm    = isfield ( headmodel, 'ihm' );
has_dsm    = isfield ( headmodel, 'dsm' );
has_hmdsm  = isfield ( headmodel, 'hm_dsm' );
has_h2em   = isfield ( headmodel, 'h2em' );
has_h2mm   = isfield ( headmodel, 'h2mm' );
has_h2xm   = iseeg && has_h2em || ismeg && has_h2mm;
has_s2mm   = isfield ( headmodel, 's2mm' );
has_h2emhm = isfield ( headmodel, 'h2em_hm' );
has_h2mmhm = isfield ( headmodel, 'h2mm_hm' );
has_h2xmhm = iseeg && has_h2emhm || ismeg && has_h2mmhm;


% Calculates the head matrix, if required.
if ~has_hm && ~has_ihm && ~has_hmdsm && ~has_h2xmhm
    
    if myom_verbosity, fprintf ( 1, 'Head model matrix not present in the data. Calculating it.\n' ); end
    
    headmodel  = myom_headmodel ( headmodel );
    has_hm     = true;
end

% Calculates the sources to head matrix, if required.
if ~has_dsm && ~has_hmdsm
    
    if myom_verbosity, fprintf ( 1, 'Source matrix not present in the data. Calculating it.\n' ); end
    
    headmodel  = myom_sourcematrix ( headmodel, grid );
    has_dsm    = true;
end

% Calculates the head to electrodes matrix, if required.
if iseeg
    
    if myom_verbosity, fprintf ( 1, 'Head to electrodes matrix not present in the data. Calculating it.\n' ); end
    
    headmodel  = myom_addelec ( headmodel, sens );
    has_h2xm   = true;
end

% Calculates the head to coils and source to coils matrices, if required.
if ismeg
    
    if myom_verbosity, fprintf ( 1, 'Head to coils and source to coils matrices not present in the data. Calculating them.\n' ); end
    
    headmodel  = myom_addcoils ( headmodel, grid, sens );
    has_h2xm   = true;
    has_s2mm   = true;
end


% Valid combinations, by preference, are:
% h2xm * hm\dsm.
% h2xm/hm * dsm.
% h2xm * inv(hm) * dsm.
% ( h2xm / hm ) * dsm.


% Calculates the leadfield using h2em * hm\dsm.
if iseeg && has_h2xm && has_hmdsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2em * headmodel.hm_dsm;
    return
end

% Calculates the leadfield using h2em/hm * dsm.
if iseeg && has_h2xmhm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2em_hm * headmodel.dsm;
    return
end

% Calculates the leadfield using h2em * inv(hm) * dsm.
if iseeg && has_h2xm && has_ihm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2em * headmodel.ihm * headmodel.dsm;
    return
end

% Calculates the leadfield using ( h2em / hm ) * dsm.
if iseeg && has_h2xm && has_hm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Expands the symmetric matrix for the head model, if required.
    if isstruct ( headmodel.hm )
        headmodel.hm = myom_struct2sym ( headmodel.hm );
    end
    
    % Calculates the leadfield.
    leadfield = ( headmodel.h2em / headmodel.hm ) * headmodel.dsm;
    return
end


% Calculates the leadfield using h2mm * hm\dsm.
if ismeg && has_h2xm && has_hmdsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2mm * headmodel.hm_dsm;
    leadfield = leadfield + headmodel.s2mm;
    return
end

% Calculates the leadfield using h2mm/hm * dsm.
if ismeg && has_h2xmhm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2mm_hm * headmodel.dsm;
    leadfield = leadfield + headmodel.s2mm;
    return
end

% Calculates the leadfield using h2mm * inv(hm) * dsm.
if ismeg && has_h2xm && has_ihm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Calculates the leadfield.
    leadfield = headmodel.h2mm * headmodel.ihm * headmodel.dsm;
    leadfield = leadfield + headmodel.s2mm;
    return
end

% Calculates the leadfield using ( h2mm / hm ) * dsm.
if ismeg && has_h2xm && has_hm && has_dsm && has_s2mm
    
    if myom_verbosity, fprintf ( 1, 'Building the leadfield matrix.\n' ); end
    
    % Expands the symmetric matrix for the head model, if required.
    if isstruct ( headmodel.hm )
        headmodel.hm = myom_struct2sym ( headmodel.hm );
    end
    
    % Calculates the leadfield.
    leadfield = ( headmodel.h2mm / headmodel.hm ) * headmodel.dsm;
    leadfield = leadfield + headmodel.s2mm;
    return
end


% If we got here, the lead field could not be calculated.
error ( 'It was not possible to calculate the lead field using the provided data.' )
