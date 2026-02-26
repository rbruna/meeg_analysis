function [ timelock, grid, scales ] = my_normalize_chans ( timelock, grid )
% 
% Based on:
% osl_normalise_sensortypes by Adam Baker

% Normalizes MEGMAG, MEGGRAD and EEG separately.
chantypes = { 'MEGMAG', 'MEGGRAD', 'EEG' };

% Generates the scaling values structure.
scales    = struct ( 'label', timelock.label, 'scale', 1 );

% Goes through each channel type.
for tindex = 1: numel ( chantypes )
    
    % Gets the covariance matrix.
    channel     = ft_channelselection ( chantypes { tindex }, timelock.label );
    chindex     = ismember ( timelock.label, channel );
    cov         = timelock.cov ( chindex, chindex );
    
    % Estimates the scaling from the eigenvalues.
    svds        = svd ( cov );
    svds        = svds ( 1: estimate_rank ( cov ) );
    chanscale   = 1 ./ sqrt ( mean ( svds ) );
    
    % Saves the scaling value.
    [ scales( chindex ).scale ] = deal ( chanscale );
    
    
    % Gets the data channels.
    channel     = ft_channelselection ( chantypes { tindex }, timelock.label );
    chindex     = ismember ( timelock.label, channel );
    
    % Escales the data.
    timelock.cov ( chindex, : ) = chanscale * timelock.cov ( chindex, : );
    timelock.cov ( :, chindex ) = chanscale * timelock.cov ( :, chindex );
    
    
    % Gets the leadfield channels.
    channel     = ft_channelselection ( chantypes { tindex }, grid.label );
    chindex     = ismember ( grid.label, channel );
    
    % Extracts the leadfield.
    leadfield   = cat ( 3, grid.leadfield { grid.inside } );
%     leadfield = double ( leadfield );
    
    % Escales the leadfield.
    leadfield ( chindex, :, : ) = chanscale * leadfield ( chindex, :, : );
    
    % Stores the leadfield.
    grid.leadfield ( grid.inside ) = num2cell ( leadfield, [ 1 2 ] );
end
