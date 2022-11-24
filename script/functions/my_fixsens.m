function sens = my_fixsens ( sens, channels )

% If no channels provided selects everything.
if nargin < 2
    channels = sens.label;
end

% Gets the indexes of the channels to remove.
remidx = ~ismember ( sens.label, channels );

% Removes the channels.
if isfield ( sens, 'label' ),    sens.label    ( remidx ) = []; end
if isfield ( sens, 'chanpos' ),  sens.chanpos  ( remidx, : ) = []; end
if isfield ( sens, 'chanori' ),  sens.chanori  ( remidx, : ) = []; end
if isfield ( sens, 'chantype' ), sens.chantype ( remidx ) = []; end
if isfield ( sens, 'chanunit' ), sens.chanunit ( remidx ) = []; end
if isfield ( sens, 'tra' ),      sens.tra      ( remidx, : ) = []; end

% Gets the list of related sensors from the mapping matrix.
if isfield ( sens, 'tra' )
    remidx = ~any ( sens.tra, 1 );
end

% Removes the related sensors.
if isfield ( sens, 'coilpos' ),  sens.coilpos  ( remidx, : ) = []; end
if isfield ( sens, 'coilori' ),  sens.coilori  ( remidx, : ) = []; end
if isfield ( sens, 'elecpos' ),  sens.elecpos  ( remidx, : ) = []; end
if isfield ( sens, 'tra' ),      sens.tra      ( :, remidx ) = []; end



% List the sensors with no position.
if isfield ( sens, 'elecpos' )
    remidx = any ( isnan ( sens.elecpos ), 2 );
elseif isfield ( sens, 'coilpos' )
    remidx = any ( isnan ( sens.coilpos ), 2 );
end

% If any sensor position is NaN removes the related channel.
if numel ( remidx )
    
    % Removes the sensors.
    if isfield ( sens, 'coilpos' ),  sens.coilpos  ( remidx, : ) = []; end
    if isfield ( sens, 'coilori' ),  sens.coilori  ( remidx, : ) = []; end
    if isfield ( sens, 'elecpos' ),  sens.elecpos  ( remidx, : ) = []; end
    if isfield ( sens, 'tra' ),      sens.tra      ( :, remidx ) = []; end
    
    % Gets the list of related channels from the mapping matrix.
    if isfield ( sens, 'tra' )
        remidx = ~any ( sens.tra, 2 );
    end
    
    % Removes the related channels.
    if isfield ( sens, 'label' ),    sens.label    ( remidx ) = []; end
    if isfield ( sens, 'chanpos' ),  sens.chanpos  ( remidx, : ) = []; end
    if isfield ( sens, 'chanori' ),  sens.chanori  ( remidx, : ) = []; end
    if isfield ( sens, 'chantype' ), sens.chantype ( remidx ) = []; end
    if isfield ( sens, 'chanunit' ), sens.chanunit ( remidx ) = []; end
    if isfield ( sens, 'tra' ),      sens.tra      ( remidx, : ) = []; end
end
