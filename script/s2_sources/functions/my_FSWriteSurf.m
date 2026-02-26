function my_FSWriteSurf ( filename, varargin )

%MY_FSWRITESURF  Generate FreeSurfer surface files.
% 
%   my_FSWriteSurf ( filename, positions, faces )
%   my_FSWriteSurf ( filename, boundary )
% 
%   Writes a surface triangulation into a FreeSurfer binary file.
%     filename  - Name of file to write.
%     positions - Nx3 matrix of vertex coordinates.
%     faces     - Mx3 matrix of face triangulation indices.
%     bounday   - FieldTrip-like bnd definition.
% 
%   The faces matrix must be Matlab compatible (no zero indices).
%   
% See also my_FSReadSurf

% Based on FreeSurfer functions:
% * write_surf by Bruce Fischl
% * fwrite3 by Bruce Fischl

if nargin < 2, error ( 'Not enough parameters.' ); end

% % Gets the triangle definition from the FreeSurfer-like surface.
if nargin == 2
    bnd   = varargin {1};
    pos   = bnd.pos;
    tri   = bnd.tri;
else
    pos   = varargin {1};
    tri   = varargin {2};
end

if size ( pos, 2 ) ~= 3, error ( 'positions must be Nx3 matrix' ); end
if size ( tri, 2 ) ~= 3, error ( 'faces must be Mx3 matrix' ); end

% Opens the file to write as Big-endian.
fid   = fopen ( filename, 'wb', 'b' );
if ( fid < 0 ), error ( 'Could not open file %s.', filename ); end


% Writes the magic number.
TRI_M  = 16777214;
fwrite ( fid, TRI_M, 'ubit24' );

% Writes two descriptive lines.
fprintf ( fid,'Created by %s on %s\n\n', getenv ( 'USER' ), datestr ( now ) );

% Writes out the number of vertices and faces.
fwrite ( fid, size ( pos, 1 ), 'int32' );
fwrite ( fid, size ( tri, 1 ), 'int32' );

% Writes out the vertice position.
fwrite ( fid, pos', 'float32' );

% Corrects the triangle definition to match FreeSurfer standards.
tri   = tri - 1;

% Writes out the triangle definition.
fwrite ( fid, tri', 'int32' );

% Closes the file.
fclose ( fid );
