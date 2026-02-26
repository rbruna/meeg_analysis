clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.figs = '../../figs/anatomy/';
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
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the data.
    mridata       = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject' );
    
    
    fprintf ( 1, 'Working with subject ''%s''.\n', mridata.subject );
    
    % Loads the MRI data and extracts the masks.
    mridata       = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri', 'mesh' );
    
    
    % If BEM, checks the geometry using OpenMEEG.
    if numel ( mridata.mesh.bnd ) == 3
        if myom_check_geometry ( mridata.mesh )
            fprintf ( 1, '  Surface meshes OK according to OpenMEEG.\n' );
        else
            fprintf ( 1, '  Surface meshes with errors according to OpenMEEG.\n' );
            fprintf ( 1, '  Press a key to continue.\n' );
            pause
        end
    end
    
    
    % Converts the meshes to millimeters.
    mesh          = mridata.mesh;
    mesh          = ft_convert_units ( mesh, 'mm' );
    
    
    % Plots the MRI, if requested.
    if config.showmri
        
        % Creates a dummy MRI containing only the anatomy.
        mri           = [];
        mri.dim       = mridata.mri.dim;
        mri.anatomy   = mridata.mri.anatomy;
        mri.transform = mridata.mri.transform;
        mri.unit      = mridata.mri.unit;
        mri.coordsys  = 'ras';
        mri           = ft_convert_units ( mri, 'mm' );
        
        ft_determine_coordsys ( mri, 'interactive', 'no' );
    end
    
    % Plots the meshes.
    for mindex = 1: numel ( mesh.tissue )
        switch mesh.tissue { mindex }
            case 'brain', meshcolor = 'brain';
            case 'skull', meshcolor = [ 1 1 1 ] - eps;
            case 'scalp', meshcolor = 'skin';
            otherwise,    meshcolor = [ 1 1 1 ] - eps;
        end
        
        ft_plot_mesh  ( mesh.bnd ( mindex ), 'facecolor', meshcolor, 'edgecolor', 'none', 'facealpha', .4 );
    end
    
    % Lights the scene.
    set ( gcf, 'Name', mridata.subject );
    delete ( findall ( gcf, 'Type', 'light' ) )
    view ( [ -140,   0 ] ), camlight
    lighting gouraud
    material dull
    rotate3d
    drawnow
    
    return
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s.png', config.path.figs, mridata.subject ) )
    if config.savefig
        savefig ( sprintf ( '%s%s.fig', config.path.figs, mridata.subject ) )
    end
    if config.savegif
        my_savegif ( sprintf ( '%s%s.gif', config.path.figs, mridata.subject ) )
    end
    close all
end
