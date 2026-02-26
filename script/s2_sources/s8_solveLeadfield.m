clc
clear
close all

% Defines the location of the files.
config.path.tran = '../../data/sources/transformation/';
config.path.lead = '../../data/sources/leadfield/';
config.path.patt = '*.mat';

% Action when the task have already been processed.
config.overwrite = true;

% Sets the coil precision for the Elekta Neuromag system.
config.coilprec  = 2;


% Creates and output folder, if needed.
if ~exist ( config.path.lead, 'dir' ), mkdir ( config.path.lead ); end


% Adds the functions folders to the path.
addpath ( sprintf ( '%s/functions/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/mne_silent/', fileparts ( pwd ) ) );
addpath ( sprintf ( '%s/functions/', pwd ) );

% Adds, if needed, the FieldTrip folder to the path.
myft_path

% Adds the FT toolboxes that will be required.
ft_hastoolbox ( 'spm8', 1, 1 );
ft_hastoolbox ( 'openmeeg', 1, 1 );

% Sets OpenMEEG in silent mode.
myom_verbosity (0)


% Gets the files list.
files = dir ( sprintf ( '%s%s', config.path.tran, config.path.patt ) );

% Goes through all the files.
for file = 1: numel ( files )
    
    % Loads the transformation.
    traninfo  = load ( sprintf ( '%s%s', config.path.tran, files ( file ).name ) );
    
    
    if exist ( sprintf ( '%s%s.mat', config.path.lead, traninfo.subject ), 'file' ) && ~config.overwrite
        fprintf ( 1, 'Ignoring subject ''%s'' (Already calculated).\n', traninfo.subject );
        continue
    end
    
    fprintf ( 1, 'Working with subject ''%s''.\n', traninfo.subject );
    
    % If no MRI defined or no MRI file, skips.
    if ~isfield ( traninfo, 'mriinfo' ) || ~isfield ( traninfo.mriinfo, 'mrifile' )
        fprintf ( 1, '  No head model defined in the transformation file. Skipping.\n' );
        continue
    end
    if ~isfield ( traninfo.mriinfo, 'transform' )
        fprintf ( 1, '  No head model transformation defined in the transformation file. Skipping.\n' );
        continue
    end
    if ~exist ( traninfo.mriinfo.mrifile, 'file' )
        fprintf ( 1, '  No head model file. Skipping.\n' );
        continue
    end
    
    
    % Gets the head shape.
    headshape = traninfo.headshape;
    
    
    % Generates the magnetometer definition with the required precision.
    if isfield ( traninfo, 'grad' ) && ft_senstype ( traninfo.grad, 'neuromag306' )
        traninfo.grad = myfiff_read_sens ( [], traninfo.header, config.coilprec );
    end
    
    % Gets the probability of the data being EEG or MEG.
    if isfield ( traninfo, 'grad' ) && ~isempty ( traninfo.grad )
        
        % Fixes the sensor definition.
        grad      = my_fixsens ( traninfo.grad );
        
        % Converts the gradiometers units to SI units (meters).
        grad      = ft_convert_units ( grad, 'm' );
        
        % The bare minimum number of sensors is 30.
        hasmeg    = numel ( grad.label ) > 30;
    else
        hasmeg    = false;
    end
    if isfield ( traninfo, 'elec' ) && ~isempty ( traninfo.elec )
        
        % Fixes the sensor definition.
        elec      = my_fixsens ( traninfo.elec );
        
        % Converts the electrodes units to SI units (meters).
        elec      = ft_convert_units ( elec, 'm' );
        
        % The bare minimum number of sensors is 30.
        haseeg    = numel ( elec.label ) > 30;
    else
        haseeg    = false;
    end
    
    % Gets sure that the sensors are correctly identified.
    if ~hasmeg && ~haseeg
        fprintf ( 2, '  Data type in subject %s can not be correctly identified. Skipping.\n', epochdata.subject );
        continue
    elseif ~hasmeg
        grad      = my_mkdum ( 'grad' );
    elseif ~haseeg
        elec      = my_mkdum ( 'elec' );
    end
    
    
    % Gets the list of variables defined in the MRI file.
    fileinfo = whos ( '-file', traninfo.mriinfo.mrifile );
    
    % If no headmodel defined in the MRI file, skips.
    if ~all ( ismember ( { 'headmodel' 'grid' }, { fileinfo.name } ) )
        fprintf ( 1, '  No head model definition in the MRI file. Skipping.\n' );
        continue
    end
    
    
    fprintf ( 1, '  Loading the head and sources models.\n' );
    
    % Loads the head and sources models.
    headdata = load ( traninfo.mriinfo.mrifile, 'mesh', 'grid', 'headmodel' );
    
    % If the data is EEG, makes sure that the model is BEM with 3 layers.
    if hasmeg && haseeg && ~any ( strcmp ( headdata.headmodel.tissue, 'scalp' ) )
        warning ( 'The data has EEG, but the head model does not accept it. Ignoring EEG channels.' )
        haseeg = false;
        elec   = my_mkdum ( 'elec' );
    end

    
    % Gets the head and sources models.
    mesh      = headdata.mesh;
    headmodel = headdata.headmodel;
    grid      = headdata.grid;
    
    % The sources are oriented with the axis of the MRI coordinate system.
    grid.ori  = eye (3);
    
    
    % Transforms the surface and the sources models to head coordinates.
    mesh      = ft_convert_units ( mesh, traninfo.mriinfo.unit );
    mesh      = ft_transform_geometry ( traninfo.mriinfo.transform, mesh );
    
    headmodel = ft_convert_units ( headmodel, traninfo.mriinfo.unit );
    headmodel = ft_transform_geometry ( traninfo.mriinfo.transform, headmodel );
    
    grid      = ft_convert_units ( grid, traninfo.mriinfo.unit );
    grid      = ft_transform_geometry ( traninfo.mriinfo.transform, grid );
    

    % Converts all the data into SI units (meters).
    mesh      = ft_convert_units ( mesh, 'm' );
    headmodel = ft_convert_units ( headmodel, 'm' );
    grid      = ft_convert_units ( grid, 'm' );
    headshape = ft_convert_units ( headshape, 'm' );
    grad      = ft_convert_units ( grad, 'm' );
    elec      = ft_convert_units ( elec, 'm' );
    
    
    fprintf ( 1, '  Sanitizing the forward model definition.\n' );
    
    % Translates the electrodes to the surface of the scalp.
    if haseeg
        scalp = headmodel.bnd ( strcmp ( headmodel.tissue, 'scalp' ) );
        for eindex = 1: size ( elec.elecpos, 1 )
            [ ~, Pm ] = NFT_dmp ( elec.elecpos ( eindex, : ), scalp.pos, scalp.tri );
            elec.elecpos ( eindex, : ) = Pm;
        end
        for eindex = 1: size ( elec.chanpos, 1 )
            [ ~, Pm ] = NFT_dmp ( elec.chanpos ( eindex, : ), scalp.pos, scalp.tri );
            elec.chanpos ( eindex, : ) = Pm;
        end
    end
    
    
    fprintf ( 1, '  Calculating the lead field.\n' );

    % Initializes the lead field.
    srcdata              = [];
    srcdata.headmodel    = headmodel;
    srcdata.sourcemodel  = grid;
    
    % Calculates the lead field for MEG.
    if hasmeg
        
        if haseeg
            fprintf ( 1, '    Calculating the lead field for MEG.\n' );
        end
        
        srcdata.sens         = grad;
        srcdata.channel      = grad.label;
        
        srcmodel_meg         = my_leadfield ( srcdata );
    end
    
    % Calculates the lead field for EEG.
    if haseeg
        
        if hasmeg
            fprintf ( 1, '    Calculating the lead field for EEG.\n' );
        end
        
        srcdata.sens         = elec;
        srcdata.channel      = elec.label;
        
        srcmodel_eeg         = my_leadfield ( srcdata );
    end
    
    % Joins the lead fields, if required.
    if hasmeg && haseeg
        srcmodel             = my_joinGrid ( srcmodel_meg, srcmodel_eeg );
    elseif hasmeg
        srcmodel             = srcmodel_meg;
    elseif haseeg
        srcmodel             = srcmodel_eeg;
    end
    
    % Removes the not needed parts of the sources model.
    srcmodel             = rmfield ( srcmodel, intersect ( fieldnames ( srcmodel ), { 'params' 'initial' } ) );
    
    
    fprintf ( 1, '  Saving calculated lead field.\n' );
    
    % Initializes the lead field variable.
    leaddata           = [];
    leaddata.subject   = traninfo.subject;
    leaddata.channel   = srcmodel.label;
    leaddata.headshape = headshape;
    leaddata.grad      = grad;
    leaddata.elec      = elec;
    leaddata.mesh      = mesh;
    leaddata.grid      = srcmodel;
    
    % Saves the lead field.
    save ( '-v6', sprintf ( '%s%s', config.path.lead, traninfo.subject ), '-struct', 'leaddata' );
end
