clc
clear
close all

% Defines the location of the files.
config.path.tran = '../../data/sources/transformation/';
config.path.figs = '../../figs/transformation/';
config.path.patt = '*.mat';

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
files = dir ( sprintf ( '%s%s', config.path.tran, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Loads the transformation information.
    traninfo = load ( sprintf ( '%s%s', config.path.tran, files ( findex ).name ) );
    
    % If no MRI information, skips the file.
    if ~isfield ( traninfo, 'mriinfo' ) || ~isfield ( traninfo.mriinfo, 'mrifile' )
        fprintf ( 1, 'Skipping subject ''%s'', task ''%s'', stage ''%s'' (no head model defined).\n', traninfo.subject, traninfo.task, traninfo.stage );
        continue
    end
    
    fprintf ( 1, 'Working with subject ''%s'', task ''%s'', stage ''%s''.\n', traninfo.subject, traninfo.task, traninfo.stage );
    
    % Loads the head and sources models.
    headdata = load ( traninfo.mriinfo.mrifile, 'mesh', 'grid' );
    
    
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
    
    
    % Gets the surface mesh(es) and the sources model.
    mesh     = headdata.mesh;
    grid     = headdata.grid;
    
    % Gets the head shape.
    hshape   = traninfo.headshape;
    
    % Gets the sensor definition(s).
    elec     = traninfo.elec;
    grad     = traninfo.grad;
    
    
    % Transforms the surface and the sources models to head coordinates.
    mesh     = ft_convert_units ( mesh, traninfo.mriinfo.unit );
    mesh     = ft_transform_geometry ( traninfo.mriinfo.transform, mesh );
    
    grid     = ft_convert_units ( grid, traninfo.mriinfo.unit );
    grid     = ft_transform_geometry ( traninfo.mriinfo.transform, grid );
    
    
    % Converts all the data into SI units (meters).
    mesh     = ft_convert_units ( mesh, 'm' );
    grid     = ft_convert_units ( grid, 'm' );
    hshape   = ft_convert_units ( hshape, 'm' );
    grad     = ft_convert_units ( grad, 'm' );
    elec     = ft_convert_units ( elec, 'm' );
    
    
    % Gets the original position of the dipoles.
    dipoleu  = grid.inside & grid.posori ( :, 3 ) >= 0;
    dipoled  = grid.inside & grid.posori ( :, 3 ) <  0;
    dipoler  = grid.inside & grid.posori ( :, 1 ) >= 0 & dipoleu;
    dipolel  = grid.inside & grid.posori ( :, 1 ) <  0 & dipoleu;
    
    % Plots the sources model.
    ft_plot_mesh ( grid.pos ( dipoled, : ), 'VertexColor', [ 0.0000 0.4470 0.7410 ], 'VertexSize', 5 );
    ft_plot_mesh ( grid.pos ( dipolel, : ), 'VertexColor', [ 0.8500 0.3250 0.0980 ], 'VertexSize', 5 );
    ft_plot_mesh ( grid.pos ( dipoler, : ), 'VertexColor', [ 0.4660 0.6740 0.1880 ], 'VertexSize', 5 );
    
    
    % Plots the surface mesh(es).
    for mindex = 1: numel ( mesh.tissue )
        switch mesh.tissue { mindex }
            case 'brain', meshcolor = 'brain';
            case 'skull', meshcolor = [ 1 1 1 ] - eps;
            case 'scalp', meshcolor = 'skin';
            otherwise,    meshcolor = [ 1 1 1 ] - eps;
        end
        
        ft_plot_mesh  ( mesh.bnd ( mindex ), 'facecolor', meshcolor, 'edgecolor', 'none', 'facealpha', .3 );
    end
    
    
    % Gets the head shape points, the fiducials and the HPI coils.
    hpiindex = strncmp ( hshape.label, 'hpi_', 4 );
    hpipos   = hshape.pos (  hpiindex, : );
    hspos    = hshape.pos ( ~hpiindex, : );
    fidpos   = hshape.fid.pos;
    
    % Plots the head shape.
    ft_plot_mesh ( hspos, 'VertexColor', [ 0 0 1 ], 'VertexSize', 5 );
    ft_plot_mesh ( fidpos, 'VertexColor', [ 0 0 0 ], 'VertexSize', 20 );
    ft_plot_mesh ( hpipos, 'VertexColor', [ 1 0 0 ], 'VertexSize', 20 );
    
    
    % Plots the sensors.
    ft_plot_mesh ( grad.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
    ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', '*', 'VertexSize', 5 );
    ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
    
    
    % Lights the scene.
    set ( gcf, 'Name', traninfo.subject );
    view ( [ -140,   0 ] ), camlight
    lighting gouraud
    material dull
    rotate3d
    drawnow
    
    fprintf ( 1, '  Showing sources by color:\n' );
    fprintf ( 1, '    Blue:  Bottom.\n' );
    fprintf ( 1, '    Red:   Top left.\n' );
    fprintf ( 1, '    Green: Top right.\n' );
    
    return
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s.png', config.path.figs, traninfo.subject ) )
    
    if config.savefig
        savefig ( sprintf ( '%s%s.fig', config.path.figs, traninfo.subject ) )
    end
    if config.savegif
        my_savegif ( sprintf ( '%s%s.gif', config.path.figs, traninfo.subject ) )
    end
    
    close all
    clc
end
