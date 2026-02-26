clc
clear
close all

% Defines the location of the files.
config.path.lead = '../../data/sources/leadfield/';
config.path.figs = '../../figs/leadfield/';
config.path.patt = '*.mat';

config.channels  = {
    'MEG0231' 'MEG1931' 'MEG0911' 'MEG1341' 'MEG0741';
    'MEG0232' 'MEG1932' 'MEG0912' 'MEG1342' 'MEG0742';
    'MEG0233' 'MEG1933' 'MEG0913' 'MEG1343' 'MEG0743';
    'EEG012'  'EEG030'  'EEG002'  'EEG015'  'EEG021' };

% Selects which versions of the figure to save.
config.savefig   = false;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Generates the output folder, if needed.
if ~exist ( config.path.figs, 'dir' ), mkdir ( config.path.figs ); end

% Gets the files list.
files = dir ( sprintf ( '%s%s', config.path.lead, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Loads the MRI data and extracts the masks.
    leaddata      = load ( sprintf ( '%s%s', config.path.lead, files ( findex ).name ) );
    
    fprintf ( '%s\n', leaddata.subject );
    
    % Converts the meshes and the grid to millimeters.
    grid          = leaddata.grid;
    
    % Gets the inside sources.
    src           = grid.pos ( grid.inside, : );
    
    % Gets the leadfield magnitud for each source.
    leadfield     = cat ( 3, grid.leadfield { grid.inside } );
    leadfield     = squeeze ( sum ( leadfield .^ 2, 2 ) );
    
    
    % Gets the channels present in the data.
    channels      = config.channels;
    datachan      = ft_channelselection ( channels, leaddata.grid.label );
    datachan      = ismember ( config.channels, datachan );
    channels ( ~any ( datachan, 2 ), : ) = [];
    datachan ( ~any ( datachan, 2 ), : ) = [];
    
    
    % Initializes the figure.
    figure
    wh = 300 * size ( channels, 1 );
    set ( gcf, 'Position', [ 0 0 1500 wh ] )
    set ( gcf, 'Name', sprintf ( '%s', leaddata.subject ) );
    
    
    
    % Goes through each row.
    for rindex = 1: size ( channels, 1 )
        
        y = 1 - rindex / size ( channels, 1 );
        h = 0.9 / size ( channels, 1 );
        
        % Goes through each column.
        for cindex = 1: size ( channels, 2 )
            
            if ~datachan ( rindex, cindex )
                continue
            end
            
            x = ( cindex - 1 ) / size ( channels, 2 );
            
            % Gets the current sensor name.
            slabel = channels ( rindex, cindex );
            
            % Gets the right sensor definition.
            if strncmp ( slabel, 'MEG', 3 )
                sensors = leaddata.grad;
            else
                sensors = leaddata.elec;
            end
            
            % Writes the sensor name.
            axes ( 'Position', [ x y .2 h ] )
            text ( 0, 0, 0, slabel, 'VerticalAlign', 'bottom', 'HorizontalAlign', 'center' )
            axis off
            xlim ( [ -1 1 ] )
            ylim ( [ -1 0 ] )
            
            % Gets the source intensity.
            maglf  = leadfield ( strcmp ( grid.label, slabel ), : )';
            maglf  = maglf - min ( maglf );
            maglf  = maglf / max ( maglf );
            colors = ones ( numel ( maglf ), 3 ) - bsxfun ( @times, [ 0 1 1 ], maglf );
            colors = colors * 0.95;
            
            
            axes ( 'Position', [ x y .2 h ] )
            hold on
            
            % Plots the sensors.
            plot3 ( sensors.chanpos ( :, 1 ), sensors.chanpos ( :, 2 ), sensors.chanpos ( :, 3 ), '.c' )
            
            % Plots the current sensor.
            sensor = my_fixsens ( sensors, slabel );
            plot3 ( sensor.chanpos ( :, 1 ), sensor.chanpos ( :, 2 ), sensor.chanpos ( :, 3 ), 'ok' )
            plot3 ( sensor.chanpos ( :, 1 ), sensor.chanpos ( :, 2 ), sensor.chanpos ( :, 3 ), '*g' )
            
            % Plots the position of the coils, if the sensor is MEG.
            if isfield ( sensor, 'coilpos' )
                plot3 ( sensor.coilpos ( :, 1 ), sensor.coilpos ( :, 2 ), sensor.coilpos ( :, 3 ), '.b' )
            end
            
            
            % Plots the sources.
            scatter3 ( src ( :, 1 ), src ( :, 2 ), src ( :, 3 ), [], colors, 'filled' )
            axis off vis3d equal
            drawnow
            
            % Generates the orientation vector.
            if strncmp ( slabel, 'MEG', 3 )
                ori = sensor.chanori;
            else
                ori = sensor.elecpos / norm ( sensor.elecpos );
            end
            
            % Sets the camera position.
            set ( gca, 'CameraPosition', [ 0.00 0.00 0.09 ] + ori * 2.2 )
            set ( gca, 'CameraTarget', [ 0.00 0.00 0.09 ] )
        end
    end
    
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s.png', config.path.figs, leaddata.subject ) )
    
    if config.savefig
        savefig ( sprintf ( '%s%s.fig', config.path.figs, leaddata.subject ) )
    end
    
    close all
end
