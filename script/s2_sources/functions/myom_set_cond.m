function headmodel = myom_set_cond ( headmodel, cond )

% Checks the input.
if numel ( cond ) ~= numel ( headmodel.bnd )
    error ( 'Incorrect number of conductivities.' )
end
if numel ( cond ) ~= numel ( headmodel.cond )
    error ( 'Incorrect number of conductivities.' )
end
if isfield ( headmodel, 'ihm' )
    error ( 'Modifying the inverse head matrix is very slow.' )
end
if isfield ( headmodel, 'hm_dsm' )
    error ( 'The combination of the source matrix and the head matrix can not be modified.' )
end


% Checks the geometrical definition of the head model.
headmodel = myom_check_headmodel ( headmodel );

% Checks the version of OpenMEEG.
if ~strncmp ( headmodel.version, '2.2' )
    error ( 'This code only works for OpenMEEG 2.2' )
end


% Gets the old and new conductivities.
oldcond = headmodel.cond;
newcond = cond;

% Adds the outside conductivity.
oldcond = cat ( 2, oldcond, 0 );
newcond = cat ( 2, newcond, 0 );

% Gets the list of surfaces.
nsurf   = numel ( headmodel.bnd );

% Gets the size of the subelement matrices.
selsz   = zeros (0);
for eindex = 1: nsurf
    selsz = cat ( 1, selsz, size ( surfs ( eindex ).pos, 1 ), size ( surfs ( eindex ).tri, 1 ) );
end
nsel    = numel ( selsz );

% Compensates the conductivity in the head matrix.
if isfield ( headmodel, 'hm' )
    
    % Reserves memory.
    mults = cell ( nsel );
    
    % Creates the basic multiplier for each subelement of the matrix.
    for eindex1 = 1: nsel
        for eindex2 = 1: nsel
            mults { eindex1, eindex2 } = ones ( selsz ( eindex1 ), selsz ( eindex2 ) );
        end
    end
    
    % Goes through each surface.
    for sindex = 1: nsurf
        
        % Auto-multiplier for the points.
        mult = ( 1 / newcond ( sindex ) + 1 / newcond ( sindex + 1 ) ) / ( 1 / oldcond ( sindex ) + 1 / oldcond ( sindex + 1 ) );
        eindex =  2 * sindex;
        mults { eindex, eindex } (:) = mult;
        
        % Auto-multiplier for the triangles.
        mult = ( newcond ( sindex ) + newcond ( sindex + 1 ) ) / ( oldcond ( sindex ) + oldcond ( sindex + 1 ) );
        eindex =  2 * sindex - 1;
        mults { eindex, eindex } (:) = mult;
        
        
        % Each surface only affects the next one.
        if sindex == nsurf, continue, end
        
        % Cross-multiplier for the points.
        mult = ( 1 / newcond ( sindex + 1 ) ) / ( 1 / oldcond ( sindex + 1 ) );
        eindex =  2 * sindex;
        mults { eindex, eindex + 2 } (:) = mult;
        mults { eindex + 2, eindex } (:) = mult;
        
        % Cross-multiplier for the triangles.
        mult = ( newcond ( sindex + 1 ) ) / ( oldcond ( sindex + 1 ) );
        eindex =  2 * sindex - 1;
        mults { eindex, eindex + 2 } (:) = mult;
        mults { eindex + 2, eindex } (:) = mult;
    end
    
    % Removes the triangles of the last surface.
    mults = mults ( 1: end - 1, 1: end - 1 );
    
    % Combines the multipliers in matrix form.
    mults = cell2mat ( mults );
    
    % Appplies the multipliers.
    headmodel.hm = mults .* headmodel.hm;
end

% Compensates the conductivity in the dipole-to-surface matrix.
if isfield ( headmodel, 'dsm' )
    
    % Reserves memory.
    mults = cell ( nsurf, 1 );
    
    % Creates the basic multiplier for each subelement of the matrix.
    for eindex = 1: nsel
        mults { eindex } = ones ( selsz ( eindex ), size ( headmodel.dsm, 2 ) );
    end
    
    % Removes the triangles of the last surface.
    mults = mults ( 1: end - 1 );
    
    % Only the triangles of the inner surface must be modified.
    mults {2} (:) = ( 1 / newcond (1) ) / ( 1 / oldcond (1) );
    
    % Combines the multipliers in matrix form.
    mults = cell2mat ( mults );
    
    % Appplies the multipliers.
    headmodel.dsm = mults .* headmodel.dsm;
end

% Compensates the conductivity in the head-to-coil matrix.
% NOT TESTED
if isfield ( headmodel, 'h2mm' )
    
    % Reserves memory.
    mults = cell ( 1, nsurf );
    
    % Creates the basic multiplier for each subelement of the matrix.
    for eindex = 1: nsel
        mults { eindex } = ones ( size ( headmodel.h2mm, 1 ), selsz ( eindex ) );
    end
    
    % Removes the triangles of the last surface.
    mults = mults ( 1: end - 1 );
    
    % Goes through each surface.
    for sindex = 1: nsurf
        
        % Only the surface points must be modified.
        mults { 2 * sindex - 1 } (:) = ( newcond ( sindex ) - newcond ( sindex + 1 ) ) / ( oldcond ( sindex ) - oldcond ( sindex + 1 ) );
    end
    
    % Combines the multipliers in matrix form.
    mults = cell2mat ( mults );
    
    % Appplies the multipliers.
    headmodel.h2mm = mults .* headmodel.h2mm;
end

% Replaces the conductivity.
headmodel.cond = cond;
