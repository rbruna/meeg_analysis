function matrix = myloreta_readBinary ( filename )

% Gets the file extension.
[ ~, ~, ext ] = fileparts ( filename );

% Opens the file to read.
fid      = fopen ( filename, 'rb' );

% Reads the header.
header   = fread ( fid, [ 1 2 ], 'single' );

% Tries to extract the data size from the header.
nsources = header (1);
ndipoles = 3 * nsources;
nsensors = header (2);

% If the first two entries are 0, 6, then the file is an old version.
if isequal ( header, [ 0 6 ] )
    
    % Reads the rest of the header.
    header   = fread ( fid, [ 1 2 ], 'single' );
    
    % Tries to extract the data size from the header.
    nsensors = header (1);
    nsources = header (2);
    ndipoles = 3 * nsources;
end

% If the header numbers are not integers there is no header.
if any ( header ~= round ( header ) )
    
    % Sets the pre-defined number of sources.
    nsources = 6239;
    ndipoles = 3 * nsources;
    
    % Calculates the number of electrodes from the file length.
    fseek ( fid, 0, 'eof' );
    nsensors = ( ftell ( fid ) / 4 ) / ndipoles;
    
    % If the number of sensors is not an integer number rises an error.
    if nsensors ~= round ( nsensors )
        
        % Closes the file and rises the error.
        fclose ( fid );
        error ( 'Incorrect file or unknown number of sources.' )
    end
    
    % Rises a warning.
    warning ( 'No header on the file. Assuming %i sources and %i electrodes.', nsources, nsensors )
    
    % Moves the pointer to the beginning of the file.
    fseek ( fid, 0, 'bof' );
end

% Reads the data as single precision (32-bit float).
matrix   = fread ( fid, 'single' );

% Closes the file.
fclose ( fid );


% The shape of the matrix depends on the extension.
switch lower ( ext )
    
    % The solution is sensors by dipoles.
    case '.spinv', matrix = reshape ( matrix, nsensors, ndipoles )';
        
    % The lead field is sensors by dipoles.
    case '.lft',   matrix = reshape ( matrix, nsensors, ndipoles );
        
    % The 'res' file is dipoles by sensors.
    case '.res',   matrix = reshape ( matrix, ndipoles, nsensors )';
        
    % The 'tm' file is dipoles by sensors, and the last entry is the rank.
    case '.tm',    matrix = reshape ( matrix ( 1: end - 1 ), nsensors, ndipoles )';
end
