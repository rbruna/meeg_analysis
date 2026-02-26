clc
clear
close all

% Defines the location of the files.
config.path.tran   = '../../data/sources/transformation/';
config.path.mni    = '../../data/headmodel/';
config.path.patt   = '*.mat';

% Defines the template head and source models to use.
config.template    = '../../template/headmodel/ICBM-NY_bem3_CTB-10mm.mat';

% Defines the head model. Can be 'bem3', 'ss' (single shell) or 'auto'.
config.model       = 'bem3';

% Defines whether the last point of the headshape is the inion.
config.hsinion     = false;

% Defines the labels for electrodes Fz, Cz, Pz, and Oz.
config.zlabels     = {'EEG009', 'EEG018', 'EEG025', 'EEG030' };

% Sets the parameters for the ICP algorythm.
config.icp.method  = 'size';
config.icp.verbose = false;

% True if the result should be plotted.
config.show        = true;
config.showmri     = true;

% Action when the task have already been processed.
config.overwrite   = true;


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );


% Loads the template.
template = load ( config.template );

% Creates and output folder, if needed.
if ~exist ( config.path.mni, 'dir' ), mkdir ( config.path.mni ); end

% Gets the files list.
files    = dir ( sprintf ( '%s%s', config.path.tran, config.path.patt ) );

% Goes through all the files.
for findex = 1: numel ( files )
    
    % Loads the transformation file.
    traninfo       = load ( sprintf ( '%s%s', config.path.tran, files ( findex ).name ) );
    
    fileinfo       = whos ( '-file', sprintf ( '%s%s', config.path.tran, files ( findex ).name ) );
    if ismember ( 'mriinfo', { fileinfo.name } ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject ''%s'', task ''%s'' (Already calculated).\n', traninfo.subject, traninfo.task );
        continue
    end
    
    fprintf ( 1, 'Working with subject ''%s'', task ''%s''.\n', traninfo.subject, traninfo.task );
    
    
    % Sanitizes the head shape definition, if required.
    if isfield ( traninfo.headshape, 'pnt' )
        traninfo.headshape.pos = traninfo.headshape.pnt;
        traninfo.headshape     = rmfield ( traninfo.headshape, 'pnt' );
        fprintf ( 1, '  Updating head shape definition.\n' );
    end
    if isfield ( traninfo.headshape.fid, 'pnt' )
        traninfo.headshape.fid.pos = traninfo.headshape.fid.pnt;
        traninfo.headshape.fid     = rmfield ( traninfo.headshape.fid, 'pnt' );
        fprintf ( 1, '  Updating head shape fiducials.\n' );
    end
    
    
    % Gets the template MRI.
    mri       = template.mri;
    mri       = my_unpackmri ( mri );
    
    % Gets the template surface mesh(es) and the sources model.
    scalp     = template.scalp;
    mesh      = template.mesh;
    grid      = template.grid;
    
    % Gets the head shape.
    hshape    = traninfo.headshape;
    
    % Gets the sensor definition(s).
    elec      = traninfo.elec;
    grad      = traninfo.grad;
    
    % Converts all the data into SI units (meters).
    mri       = ft_convert_units ( mri, 'm' );
    scalp     = ft_convert_units ( scalp, 'm' );
    mesh      = ft_convert_units ( mesh, 'm' );
    grid      = ft_convert_units ( grid, 'm' );
    hshape    = ft_convert_units ( hshape, 'm' );
    grad      = ft_convert_units ( grad, 'm' );
    elec      = ft_convert_units ( elec, 'm' );
    
    
    % Sanitizes the surface meshes.
    if strcmp ( config.model, 'bem3' ) && ~strncmp ( mesh.type, 'bem', 3 )
        fprintf ( 1, 'Ignoring subject %s (not valid for three-layer BEM).\n', mridata.subject );
        continue
    end
    
    % Converts the surface into single-shell, if requested.
    if strcmp ( config.model, 'ss' ) && ~strcmp ( mesh.type, 'ss' )
        
        % Gets only the brain surface mesh.
        hit               = strcmp ( mesh.tissue, 'brain' );
        mesh.type         = 'singleshell';
        mesh.tissue       = mesh.tissue ( hit );
        mesh.bnd          = mesh.bnd ( hit );
    end
    
    
    % Adds the inion in MNI coordinates to the template, if required.
    if ~ismember ( scalp.fid.label, 'inion' )
        scalp.fid.label ( 4 ) = { 'Inion' };
        scalp.fid.pos ( 4, : ) = [ +0.000 -0.116 -0.028 ];
    end
    
    
    % If no inion defined in the fiducials, tries to add it.
    if ~ismember ( 'Inion', hshape.fid.label )
        
        % Uses the last point of the head shape, if requested.
        if config.hsinion
            
            % Defines the inion.
            inion = hshape.pos ( end, : );
            
            % Adds the inion as a head shape fiducial.
            hshape.fid.pos   = cat ( 1, hshape.fid.pos, inion );
            hshape.fid.label = cat ( 1, hshape.fid.label, 'Inion' );
            
        % Otherwise uses the zero-line electrodes, if requested.
        elseif ( numel ( config.zlabels ) == 4 ) && all ( ismember ( config.zlabels, elec.label ) )
            
            % Gets the position of the electrodes in the zero-line.
            hits  = my_matchstr ( elec.label, config.zlabels );
            zpos  = elec.elecpos ( hits, : );
        
            % Gets the average 20 % distance.
            d20   = mean ( sqrt ( sum ( diff ( zpos, [], 1 ).^ 2, 2 ) ) );

            % Defines the inion as a point 10 % below Oz.
            inion = zpos ( 4, : ) - [ 0 0 d20 ] / 2;
            
            % Adds the inion as a head shape fiducial.
            hshape.fid.pos   = cat ( 1, hshape.fid.pos, inion );
            hshape.fid.label = cat ( 1, hshape.fid.label, 'Inion' );
        end
    end
    
    
    % Keeps only the fiducials common to the MRI and the headshape.
    fiducial          = intersect ( hshape.fid.label, scalp.fid.label );
    hshapefid         = my_matchstr ( hshape.fid.label, fiducial );
    hshape.fid.label  = hshape.fid.label ( hshapefid );
    hshape.fid.pos    = hshape.fid.pos   ( hshapefid, : );
    scalpfid          = my_matchstr ( hshape.fid.label, fiducial );
    scalp.fid.label   = scalp.fid.label ( scalpfid );
    scalp.fid.pos     = scalp.fid.pos   ( scalpfid, : );
    
    % Removes from the headshape the points not present in the template.
    hsshort           = hshape;
    hsremove          = hsshort.pos ( :, 3 ) < -0.03;
    hsshort.pos       = hsshort.pos ( ~hsremove, : );
    
    
    fprintf ( 1, '  Aligning the template to the subject''s headshape.\n' );
    
    % Uses a rigid transform to fit the scalp and headhsape fiducials.
    trans1            = my_fitFiducials ( hsshort, scalp );
    indscalp          = ft_transform_geometry ( trans1, scalp );
    
    % Adds 10 copies of the fiducials as new points.
    dumscalp          = cat ( 1, indscalp.pos, repmat ( indscalp.fid.pos, 10, 1 ) );
    dumhshape         = cat ( 1, hsshort.pos, repmat ( hsshort.fid.pos, 10, 1 ) );
    
    % Uses a ICP algorithm to fit the headshape points to the scalp.
    invtrans2         = my_icp ( dumscalp, dumhshape, config.icp );
    indscalp          = ft_transform_geometry ( inv ( invtrans2 ), indscalp );
    
    % Uses a ICP algorithm again only with the original points.
    invtrans3         = my_icp ( indscalp.pos, hsshort.pos, config.icp );
    indscalp          = ft_transform_geometry ( inv ( invtrans3 ), indscalp );
    
    % Builds the transformation matrix from template to individual space.
    transform         = ( invtrans3 * invtrans2 ) \ trans1;
    
    
    % Transforms the template anatomy to subject space.
    mri.transform     = transform * mri.transform;
    scalp             = ft_transform_geometry ( transform, scalp );
    mesh              = ft_transform_geometry ( transform, mesh );
    grid              = ft_transform_geometry ( transform, grid );
    
    % Transforms the MRI to the original units.
    mri               = ft_convert_units ( mri, template.mri.unit );
    
    
    % Creates a head model data structure for the subject.
    % Head model data has no 'transform' field to preclude using s6.
    headdata          = [];
    headdata.subject  = traninfo.subject;
    headdata.model    = strcat ( template.subject, '-', template.model );
    headdata.sources  = template.sources;
    headdata.mri      = my_packmri ( mri );
    headdata.landmark = template.landmark;
    headdata.scalp    = scalp;
    headdata.mesh     = mesh;
    headdata.grid     = grid;
    
    
    % Shows the result, if requested.
    if config.show
        figure
        
        % Plots the head shape.
        ft_plot_mesh ( hshape, 'VertexColor', [ 0 0 1 ], 'VertexSize', 5 );
        ft_plot_mesh ( hshape.fid, 'VertexColor', [ 0 0 0 ], 'VertexSize', 20 );
        
        % Plots the head model anatomy.
        ft_plot_mesh ( scalp.bnd, 'facealpha', 0.5, 'facecolor', 'skin' )
        ft_plot_mesh ( scalp.fid, 'VertexColor', [ 1 0 0 ], 'VertexSize', 20 );
        
        % Plots the sensors.
        ft_plot_mesh ( grad.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
        ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', '*', 'VertexSize', 5 );
        ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
        
        % Lights the scene.
        set ( gcf, 'Name', traninfo.subject );
        delete ( findall ( gcf, 'Type', 'light' ) )
        view (   90,    0 ), camlight
        view ( -140,    0 ), camlight
        lighting gouraud
        material dull
        rotate3d
%         uiwait
%         pause (1)
%         close
    end
    
    % Shows the result, if requested.
    if config.show
        
        % Plots the MRI, if requested.
        if config.showmri

            % Creates a dummy MRI containing only the anatomy.
            mri           = [];
            mri.dim       = headdata.mri.dim;
            mri.anatomy   = headdata.mri.anatomy;
            mri.transform = headdata.mri.transform;
            mri.unit      = headdata.mri.unit;
            mri.coordsys  = 'ras';
            mri           = ft_convert_units ( mri, 'm' );

            ft_determine_coordsys ( mri, 'interactive', 'no' );
        end
        
        % Plots the head and sources models.
        ft_plot_mesh ( mesh.bnd, 'EdgeAlpha', 0.05, 'FaceAlpha', 0.1 )
        ft_plot_mesh ( grid.pos ( grid.inside, : ), 'VertexColor', 'g' )
        
        % Plots the sensors.
        ft_plot_mesh ( grad.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
        ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', '*', 'VertexSize', 5 );
        ft_plot_mesh ( elec.chanpos, 'VertexColor', [ 0.6350 0.0780 0.1840 ], 'VertexMarker', 'o', 'VertexSize', 5 );
        
        
        % Lights the scene.
        set ( gcf, 'Name', headdata.subject );
        delete ( findall ( gcf, 'Type', 'light' ) )
        view (   90,    0 ), camlight
        view ( -140,    0 ), camlight
        lighting gouraud
        material dull
        rotate3d
        drawnow
%         uiwait
%         continue
    end
    
    
    fprintf ( 1, '  Saving the modified template head model.\n' );
    
    % Saves the modified template head model.
    save ( '-v6', sprintf ( '%s%s_%s_%s.mat', config.path.mni, headdata.subject, headdata.model, headdata.sources ), '-struct', 'headdata' );
    
    
    fprintf ( 1, '  Saving the transformation information.\n' );
    
    % Gets the output data.
    mriinfo           = [];
    mriinfo.mrifile   = sprintf ( '%s%s_%s_%s.mat', config.path.mni, headdata.subject, headdata.model, headdata.sources );
    mriinfo.unit      = template.mri.unit;
    mriinfo.transform = eye (4);
    
    % Adds the anatomy information to the transformation file.
    traninfo.mriinfo = mriinfo;
    
    % Saves the transformation file.
    save ( '-v6', sprintf ( '%s%s_%s', config.path.tran, traninfo.subject, traninfo.task ), '-struct', 'traninfo' );
end
