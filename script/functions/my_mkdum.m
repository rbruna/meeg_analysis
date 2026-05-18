function output = my_mkdum ( type )

% Initializes the output.
output = struct ();

switch type

    % First case: Gradiometers structure.
    case 'grad'
        output.label     = {};
        output.chanpos   = zeros ( 0, 3 );
        output.chanori   = zeros ( 0, 3 );
        output.coilpos   = zeros ( 0, 3 );
        output.coilori   = zeros ( 0, 3 );
        output.tra       = [];
        output.unit      = 'm';

    % Second case: Electrodes structure.
    case 'elec'
        output.label     = {};
        output.chanpos   = zeros ( 0, 3 );
        output.elecpos   = zeros ( 0, 3 );
        output.tra       = [];
        output.unit      = 'm';

    % Third case: FieldTrip events structure.
    case 'event'
        output.type      = [];
        output.sample    = [];
        output.value     = [];
        output.offset    = [];
        output.duration  = [];
        output.timestamp = [];

        output = output ( [] );


    % General case: Writes a message.
    otherwise
        fprintf ( 1, 'Unknown requested data type.\n' );
end
