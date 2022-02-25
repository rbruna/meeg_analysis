function data = my_rejectartifact ( cfg, data )

% Steps:
% * Extracts the trl from the sampleinfo.
% * Checks that the trl is correct (trial length and number of trials).
% * Stablishes the relation between samples and trial times.
% * Limits the trl to the critical window, if any.
% * Concatenates all the artifacts.
% * Looks for artifacts in the trl.


% Checks that the data has 'sampleinfo'.
if ~isfield ( data, 'sampleinfo' )
    error ( 'Data must include sample information.' );
end

% If critical time window the data must include sampling rate.
if isfield ( cfg.artfctdef, 'crittoilim' ) && ~isfield ( data, 'fsample' )
    error ( 'Data must include sampling rate information to use the ''crittoilim'' option.' );
end

% Checks that the input is raw data.
if ~israw ( data )
    error ( 'Invalid data input.' );
end


% Gets the 'sampleinfo' field.
trl = data.sampleinfo;

% Checks that the sampleinfo is valid for the current data.
if size ( trl, 1 ) ~= numel ( data.time )
    error ( 'Sample information is not consistent with the data.' );
end
if diff ( trl, [], 2 ) + 1 ~= cellfun ( @(t) numel ( t ), data.time (:) )
    error ( 'Sample information is not consistent with the data.' );
end

% Appends the offset to the sample information.
trl = cat ( 2, trl, -cellfun ( @(t) sum ( t < 0 ), data.time (:) ) );


% Restricts the sample information to the critical window.
if isfield ( cfg.artfctdef, 'crittoilim' )
    
    % Gets the sample equivalence of the critical window.
    scrit = round ( cfg.artfctdef.crittoilim * data.fsample );
    
    % Transforms the critical window to on-data samples.
    scrit = bsxfun ( @minus, scrit, trl ( :, 3 ) - trl ( :, 1 ) );
    
    % Limits the critical window to trial samples.
    scrit ( :, 1 ) = max ( scrit ( :, 1 ), trl ( :, 1 ) );
    scrit ( :, 2 ) = min ( scrit ( :, 2 ), trl ( :, 2 ) );
    
% Otherwise the whole trial is critical.    
else
    
    scrit = trl ( :, 1: 2 );
end





% Gets the artifact samples.
sart  = cfg.artfctdef;

% Converts the artifacts to matrix form, if needed.
if isstruct ( sart )
    sart  = struct2cell ( sart );
    if isstruct ( sart {1} )
        sart ( ~cellfun ( @isstruct, sart ) ) = [];
        sart = cellfun ( @(artifacts) artifacts.artifact, sart, 'UniformOutput', false );
    end
    
    % Concatenates all the artifacts.
    sart  = cat ( 1, sart {:} );
end

% Sorts the artifact definitions.
sart  = sortrows ( sart );


% Combines overlapping artifacts.
for aindex = 1: size ( sart, 1 )
    
    % If this is the last artifact, exits.
    if aindex == size ( sart, 1 ), break; end
    
    % If the current artifac overlaps with the next one, merges them.
    if sart ( aindex, 2 ) > sart ( aindex + 1, 1 )
        sart ( aindex + 1, 1 ) = min ( sart ( aindex, 1 ), sart ( aindex + 1, 1 ) );
        sart ( aindex + 1, 2 ) = max ( sart ( aindex, 2 ), sart ( aindex + 1, 2 ) );
        sart ( aindex, : ) = NaN;
    end
end

sart  = sart ( ~any ( isnan ( sart ), 2 ), : );




% Gets the list of artifacts before and after each trial.
aart  = bsxfun ( @gt, scrit ( :, 1 ), sart ( :, 2 )' );
bart  = bsxfun ( @lt, scrit ( :, 2 ), sart ( :, 1 )' );

% Artifacts in neither of the categories overlaps with the trial.
atrl  = ~all ( aart | bart, 2 );


cfg = [];
cfg.trials = find ( ~atrl );
data=ft_selectdata ( cfg, data );





function output = israw ( input )

% The minimum fields are 'label', 'time' and 'trial'.
output = isfield ( input, { 'label', 'time', 'trial' } );

if ~output, return, end

% 'time' and 'trial' must be cells of the same lenght.
output = iscell ( input.time ) && iscell ( input.trial );

if ~output, return, end

% 'time' and 'trial' must be cells of the same lenght.
output = numel ( input.time ) == numel ( input.trial );