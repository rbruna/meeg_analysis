clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.figs = '../../figs/landmarks/';
config.path.patt = '*.mat';

% Selects which versions of the figure to save.
config.savefig   = false;


% Creates and output folder, if needed.
if ~exist ( config.path.figs, 'dir' ), mkdir ( config.path.figs ); end


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path


% Gets the file list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

for findex = 1: numel ( files )
    
    mridata = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ) );
    
    dummy            = [];
    dummy.anatomy    = mridata.mri.anatomy;
    dummy.dim        = mridata.mri.dim;
    dummy.transform  = mridata.mri.transform;
    dummy.coordsys   = mridata.mri.coordsys;
    dummy.unit       = mridata.mri.unit;
    
    
    cfg = [];
    cfg.location = mridata.landmark.acpc.ac;
    cfg.locationcoordinates = 'voxel';
    
    ft_sourceplot ( cfg, dummy )
    set ( gcf, 'Name', sprintf ( '%s - AC', mridata.subject ) );
    
    if config.savefig
        savefig ( sprintf ( '%s%s AC.fig', config.path.figs, mridata.subject ) )
    end
    
    print ( '-dpng', sprintf ( '%s%s AC.png', config.path.figs, mridata.subject ) );
    close
    
    
    cfg = [];
    cfg.location = mridata.landmark.acpc.pc;
    cfg.locationcoordinates = 'voxel';
    
    ft_sourceplot ( cfg, dummy )
    set ( gcf, 'Name', sprintf ( '%s - PC', mridata.subject ) );
    
    if config.savefig
        savefig ( sprintf ( '%s%s PC.fig', config.path.figs, mridata.subject ) )
    end
    
    print ( '-dpng', sprintf ( '%s%s PC.png', config.path.figs, mridata.subject ) );
    close
    
    
    cfg = [];
    cfg.location = mridata.landmark.acpc.xzpoint;
    cfg.locationcoordinates = 'voxel';
    
    ft_sourceplot ( cfg, dummy )
    set ( gcf, 'Name', sprintf ( '%s - XZpoint', mridata.subject ) );
    
    if config.savefig
        savefig ( sprintf ( '%s%s XZpoint.fig', config.path.figs, mridata.subject ) )
    end
    
    print ( '-dpng', sprintf ( '%s%s XZpoint.png', config.path.figs, mridata.subject ) );
    close
end
