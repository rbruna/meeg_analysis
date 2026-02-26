clc
clear
close all

% Defines the location of the files.
config.path.mri  = '../../data/anatomy/MAT/';
config.path.figs = '../../figs/segmentation/';
config.path.patt = '*.mat';

% Selects which versions of the figure to save.
config.savefig   = false;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );


% Generates the output folder, if needed.
if ~exist ( config.path.figs, 'dir' ), mkdir ( config.path.figs ); end

% Gets the file list.
files = dir ( sprintf ( '%s%s', config.path.mri, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Pre-loads the MRI.
    mridata          = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject' );
    
    
    fprintf ( 1, 'Working on subject %s.\n', mridata.subject );
    
    % Loads the MRI.
    mridata          = load ( sprintf ( '%s%s', config.path.mri, files ( findex ).name ), 'subject', 'mri' );
    mri              = my_unpackmri ( mridata.mri );
    
    % Gets the segmented MRI.
    dummy            = [];
    dummy.anatomy    = mri.anatomy;
    dummy.dim        = mri.dim;
    dummy.transform  = mri.transform;
    dummy.coordsys   = mri.coordsys;
    dummy.unit       = mri.unit;
    
    
    % Convert the masks to indexed representation.
    maskpos          = strcmpi ( mri.masklabel, 'Scalp' );
    dummy.seg        = double ( mri.mask ( :, :, :, maskpos ) );
    dummy.seg ( mri.csf + mri.gray + mri.white > .1 ) = 3;
    dummy.seg ( mri.bone  > .5 ) = 2;
    dummy.seg ( mri.csf   > .5 ) = 3;
    dummy.seg ( mri.gray  > .5 ) = 4;
    dummy.seg ( mri.white > .5 ) = 5;
    dummy.seglabel   = { 'scalp' 'skull' 'brain' 'gray' 'white' };
    
    cfg              = [];
    cfg.funparameter = 'seg';
    cfg.funcolormap  = [ 0 0 0; 1 0 0; 0 1 0; 0 0 1; .8 .8 .8; 1 1 1 ];
    cfg.funcolorlim  = [ -0.5 +5.5 ];
    cfg.location     = 'center';
    
    ft_sourceplot ( cfg, dummy );
    
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s.png', config.path.figs, mridata.subject ) )
    
    if config.savefig
        savefig ( sprintf ( '%s%s.fig', config.path.figs, mridata.subject ) )
    end
    close all
    clc
    
    
    cfg              = [];
    cfg.funparameter = 'seg';
    cfg.funcolormap  = [ 0 0 0; 1 0 0; 0 1 0; 0 0 1; .8 .8 .8; 1 1 1 ];
    cfg.funcolorlim  = [ -0.5 +5.5 ];
    cfg.method       = 'slice';
    
    ft_sourceplot ( cfg, dummy );
    
    % Saves the figure.
    print ( '-dpng', sprintf ( '%s%s_slices.png', config.path.figs, mridata.subject ) )
    
    if config.savefig
        savefig ( sprintf ( '%s%s_slices.fig', config.path.figs, mridata.subject ) )
    end
    close all
    clc
    
%     set ( gcf, 'Position', get ( 0, 'ScreenSize' ) .* [ 1 1 .5 1 ] );
%     set ( gcf, 'Name', mridata.subject );
%     uiwait
%     close all
%     drawnow
end
