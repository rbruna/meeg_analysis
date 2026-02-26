clc
clear
close all

% Defines the location of the files.
config.path.head = '../../data/headmodel/';
config.path.figs = '../../figs/headmodel/';
config.path.patt = '*.mat';

% Shows the MRI or not.
config.showmri   = true;

% Selects which versions of the figure to save.
config.savefig   = false;
config.savegif   = true;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'iso2mesh', 1, 1 );
ft_hastoolbox ( 'openmeeg', 1, 1 );


% Generates the output folder, if needed.
if ~exist ( config.path.figs, 'dir' ), mkdir ( config.path.figs ); end


% Gets the files list.
files = dir ( sprintf ( '%s%s', config.path.head, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the data.
    headdata      = load ( sprintf ( '%s%s', config.path.head, files ( findex ).name ), 'subject' );
    
    
    fprintf ( 1, 'Working with subject %s.\n', headdata.subject );
    
    % Loads the MRI data and extracts the masks.
    headdata      = load ( sprintf ( '%s%s', config.path.head, files ( findex ).name ), 'subject', 'mri', 'mesh', 'grid' );
    
    
    % If BEM, checks the geometry using OpenMEEG.
    if numel ( headdata.mesh.bnd ) == 3
        if myom_check_geometry ( headdata.mesh )
            fprintf ( 1, '  Surface meshes OK according to OpenMEEG.\n' );
        else
            fprintf ( 1, '  Surface meshes with errors according to OpenMEEG.\n' );
            fprintf ( 1, '  Press a key to continue.\n' );
            pause
        end
    end
    
    
    % Converts the meshes and the grid to millimeters.
    mesh          = headdata.mesh;
    mesh          = ft_convert_units ( mesh, 'mm' );
    grid          = headdata.grid;
    grid          = ft_convert_units ( grid, 'mm' );
    
    
    % Plots the MRI, if requested.
    if config.showmri
        
        % Creates a dummy MRI containing only the anatomy.
        mri           = [];
        mri.dim       = headdata.mri.dim;
        mri.anatomy   = headdata.mri.anatomy;
        mri.transform = headdata.mri.transform;
        mri.unit      = headdata.mri.unit;
        mri.coordsys  = 'ras';
        mri           = ft_convert_units ( mri, 'mm' );
        
        ft_determine_coordsys ( mri, 'interactive', 'no' );
    end
    
    % Gets the original position of the dipoles.
    dipoleu  = grid.inside & grid.posori ( :, 3 ) >= 0;
    dipoled  = grid.inside & grid.posori ( :, 3 ) <  0;
    dipoler  = grid.inside & grid.posori ( :, 1 ) >= 0 & dipoleu;
    dipolel  = grid.inside & grid.posori ( :, 1 ) <  0 & dipoleu;
    
    % Plots the source model.
    ft_plot_mesh  ( grid.pos ( dipoled, : ), 'VertexColor', [ 0.0000 0.4470 0.7410 ], 'VertexSize', 5 );
    ft_plot_mesh  ( grid.pos ( dipolel, : ), 'VertexColor', [ 0.8500 0.3250 0.0980 ], 'VertexSize', 5 );
    ft_plot_mesh  ( grid.pos ( dipoler, : ), 'VertexColor', [ 0.4660 0.6740 0.1880 ], 'VertexSize', 5 );
    
    % Plots the meshes.
    for mindex = 1: numel ( mesh.tissue )
        switch mesh.tissue { mindex }
            case 'brain', meshcolor = 'brain';
            case 'skull', meshcolor = [ 1 1 1 ] - eps;
            case 'scalp', meshcolor = 'skin';
            otherwise,    meshcolor = [ 1 1 1 ] - eps;
        end
        
        ft_plot_mesh  ( mesh.bnd ( mindex ), 'facecolor', meshcolor, 'edgecolor', 'none', 'facealpha', .3 );
    end
    
    % Lights the scene.
    set ( gcf, 'Name', headdata.subject );
    delete ( findall ( gcf, 'Type', 'light' ) )
    view ( [ -140,   0 ] ), camlight
    lighting gouraud
    material dull
    rotate3d
    drawnow
    
    fprintf ( 1, '  Showing sources by color:\n' );
    fprintf ( 1, '    Blue:  Bottom.\n' );
    fprintf ( 1, '    Red:   Top left.\n' );
    fprintf ( 1, '    Green: Top right.\n' );
    
    
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s.png', config.path.figs, headdata.subject ) )
    if config.savefig
        savefig ( sprintf ( '%s%s.fig', config.path.figs, headdata.subject ) )
    end
    if config.savegif
        my_savegif ( sprintf ( '%s%s.gif', config.path.figs, headdata.subject ) )
    end
    close all
end
