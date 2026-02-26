function myom_save_full ( data, filename, format )

% Based on the OpenMEEG functions:
% * om_save_full by Alexandre Gramfort

if nargin < 3
    format = 'binary';
end

data = double ( data );
dims = size ( data );

switch format
    case 'binary'
        fid = fopen ( filename, 'w' );
        fwrite ( fid, dims, 'uint32', 'ieee-le' );
        fwrite ( fid, data (:), 'double', 'ieee-le' );
        fclose ( fid );
        
    case 'ascii'
        save ( filename, 'data', '-ASCII', '-double' )
        
    otherwise
        error ( 'Unknown file format.' )
end
