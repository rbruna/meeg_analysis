function my_savegif ( varargin )

nviews = 50;
fps    = 15;
res    = 150;

% If no axes returns.
if ~numel ( findobj ( 0, 'Type', 'axes' ) ), return, end

if ~nargin
    ax       = findobj ( gcf, 'Type', 'Axes' );
    filename = 'file.gif';
end

if nargin == 1
    if ishandle ( varargin {1} )
        ax       = varargin {1};
        filename = 'file.gif';
    else
        ax       = findobj ( gcf, 'Type', 'Axes' );
        filename = varargin {1};
    end
end

if nargin == 2
    ax       = varargin {1};
    filename = varargin {2};
end

if isempty ( ax )
    return
end


% Defines the views.
views  = linspace ( -180, 180, nviews + 1 );
views  = views ( 1: end - 1 );


% Reserves memory for the figure.
images = cell ( nviews, 1 );

% Goes through each slice.
for vindex = 1: nviews
    
    % Rotates the axes(es).
    for aindex = 1: numel ( ax )
        view ( ax ( aindex ), views ( vindex ), 0 );
    end
    
    % Lights the scene.
    delete ( findall ( ax, 'Type', 'light' ) )
    camlight
    
    % Gets the figure as a RGB bit map.
    images { vindex } = print ( '-RGBImage', sprintf ( '-r%.0f', res ) );
end

% Concatenates all the frames.
images = cat ( 2, images {:} );

% Generates an optimal dictionary plus white.
[ ~, dic ] = rgb2ind ( images, 255 );
dic    = cat ( 1, [ 1 1 1 ], dic );

% Quantizes the bit map with the dictionary.
imsind = rgb2ind ( images, dic );
imsind = reshape ( imsind, size ( imsind, 1 ), [], 1, nviews );

% Writes the figure as a GIF.
imwrite ( imsind, dic, filename, 'gif', 'DelayTime', 1 / fps, 'Loopcount', inf );
