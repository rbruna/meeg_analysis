function varargout = my_FSReadSurf ( filename )

%MY_FSREADSURF  Read FreeSurfer surface files.
% 
%   [ positions, faces ] = my_FSReadSurf ( filename )
%   [ boundary ]         = my_FSReadSurf ( filename )
% 
%   Writes a surface triangulation into a FreeSurfer binary file.
%     filename  - Name of file to write.
%     positions - Nx3 matrix of vertex coordinates.
%     faces     - Mx3 matrix of face triangulation indices.
%     bounday   - FieldTrip-like bnd definition.
% 
%   The result faces matrix is Matlab compatible (no zero indices).
%   
% See also my_FSWriteSurf

% Based on FreeSurfer functions:
% * read_surf by Bruce Fischl
% * fread3 by Bruce Fischl

if nargin < 1, error ( 'Not enough parameters.' ); end


% Opens the file to read as Big-endian.
fid   = fopen ( filename, 'rb', 'b' );
if ( fid < 0 ), error ( 'Could not open file %s.', filename ); end


% Defines the recognized magic numbers.
TRI_M = 16777214;
TET_M = 16777215;

% Reads the magic number from the first 3 bytes of data.
magic = fread ( fid, 1, 'ubit24' );

% Selects the appropriate routine to read the file.
switch magic
    case TET_M
        % Gets the number of vertices and faces.
        npnt  = fread ( fid, 1, 'ubit24' );
        ntri  = fread ( fid, 1, 'ubit24' );
        
        % Reads the data.
        pos   = fread ( fid, [ 3 npnt ], 'int16')' ./ 100;
        tri   = fread ( fid, [ 4 ntri ], 'ubit24' )' + 1;
        
    case TRI_M
        
        % Ignores the first two lines.
        fgets ( fid );
        fgets ( fid );
        
        % Gets the number of vertices and faces.
        npnt  = fread ( fid, 1, 'int32' );
        ntri  = fread ( fid, 1, 'int32' );
        
        % Reads the data.
        pos   = fread ( fid, [ 3 npnt ], 'float32' )';
        tri   = fread ( fid, [ 3 ntri ], 'int32' )';
        
    otherwise
        error ( 'Wrong file type.' )
end

% Corrects the cras, if provided.
while ~feof ( fid )
    line = fgetl ( fid );
    match = regexp ( line, 'cras += ([-\d.]+) ([-\d.]+) ([-\d.]+)', 'tokens' );
    
    if numel ( match )
        corr = cellfun ( @str2num, match {1} );
        pos  = bsxfun ( @plus, pos, corr );
    end
end

% Closes the file.
fclose ( fid );

% Corrects the triangle definition to match Matlab standards.
tri   = tri + 1;

% % Creates the FieldTrip-like surface.
bnd = struct ( 'pos', pos, 'tri', tri );

if nargout == 1
    varargout {1} = bnd;
else
    varargout {1} = pos;
    varargout {2} = tri;
end
