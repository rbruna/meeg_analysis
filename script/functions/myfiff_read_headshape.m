function headshape = myfiff_read_headshape ( filename, header )

% The FIFF headpoints structure is:
% - kind defines the type of point:
%   1 Cardinal landmark.
%   2 HPI coil.
%   3 EEG/ECG electrode location.
%   4 Head surface point.
% - ident defines the ordinal point in the givan kind. For the landmarks:
%   1 Left pre-auricular
%   2 Nasion
%   3 Right pre-auricular
% - coord_frame is the coordinates system:
%   0 Unknown.
%   1 Device coordinates frame.
%   2 Polhemus coordinates frame.
%   3 HPI coordinates frame.
%   4 Head coordinates frame.
%   5 MRI coordinates frame.

% Gets the file header, if no provided.
if nargin < 2
    header = ft_read_header ( filename );
end


% Gets the raw FIFF header.
info  = header.orig;

% Gets all the digitalized points.
point = info.dig;

% Gets the device to head transform matrix.
if ~isfield ( info, 'dev_head_t' )
    trans    = [];
else
    trans  = info.dev_head_t;
end


% If no transformation matrix, keeps only one coordinate frame.
if isempty ( trans )
    
    % Gets the most common coordinate frame.
    coordsys = mode ( [ point.coord_frame ] );
    
    % Removes the points in other coordinate frames.
    point ( [ point.coord_frame ] ~= coordsys ) = [];
    
% Otherwise transforms everything to head frame.
else
    
    % Gets the coordinate frame.
    coordsys  = 4;
    
    % Modifies the coordinate frame for the points in device frame.
    fixpoints = find ( [ point.coord_frame ] == 1 );
    
    for pindex = fixpoints (:)'
        
        % Transforms the point to head frame.
        point ( pindex ).r = transform_coordsys ( point ( pindex ).r, trans );
        point ( pindex ).coord_frame = 4;
    end
    
    % Removes the points in other coordinate frames.
    point ( [ point.coord_frame ] ~= coordsys ) = [];
end

% Removes the NaNs.
hasnan = cellfun ( @(x) any ( isnan ( x ) ), { point.r } );
point  = point ( ~hasnan );

% Gets the head point positions and labels.
label = cellfun ( @label_headpoint, { point.ident }, { point.kind }, 'UniformOutput', false );
point = cat ( 2, point.r )';

% Extracts the landmarks.
landmark.pnt   = point ( strncmp ( label, 'fid_', 4 ), : );
landmark.label = label ( strncmp ( label, 'fid_', 4 ) )';

% Removes the landmarks from the head points.
point ( strncmp ( label, 'fid_', 4 ), : ) = [];
label ( strncmp ( label, 'fid_', 4 ) ) = [];

% Replaces the fiducial index for the landmark name.
landmark.label = strrep ( landmark.label, 'fid_1', 'LPA' );
landmark.label = strrep ( landmark.label, 'fid_2', 'Nasion' );
landmark.label = strrep ( landmark.label, 'fid_3', 'RPA' );


% Defines the coordinate frame.
switch coordsys
    case 1,    coordsys = 'dewar';
    case 4,    coordsys = 'neuromag';
    otherwise, coordsys = 'unknown';
end

% Constructs the output structure.
headshape.pnt      = point;
headshape.fid      = landmark;
headshape.label    = label;
headshape.coordsys = coordsys;
headshape.unit     = 'm';


function point = transform_coordsys ( point, trans )

% Extends the point definition.
point ( 4, : ) = 1;

% Applies the transformation
point = trans * point;

% Removes the extension.
point ( 4, : ) = [];


function label = label_headpoint ( index, type )

% Labels the headpoint according to the type.
switch type
    
    case 1, label = 'fid';
    case 2, label = 'hpi';
    case 3, label = 'eeg';
    case 4, label = 'extra';
end

% Adds the index.
label = strcat ( label, '_', num2str ( index ) );
