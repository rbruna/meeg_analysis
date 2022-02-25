function trl = restingSegmentation ( cfg )
% trialfunRestingOverlap ( config )
%
% Segments the data according to the 'config' structure.
% Structure fields are:
% - config.dataset:  Data file.
% - config.header:   Dataset header (optional).
% - config.begtime:  Beggining time, in seconds.
% - config.endtime:  Ending time, in seconds.
% - config.segment:  Epoch duration, in seconds.
% - config.overlap:  Overlap between consecutive segments, in seconds.
% - config.equal:    Sets if all the segments have the same duration.
% - config.padding:  Padding time length, in seconds.
% - config.addpadd:  Sets if the padding is part of the trial.
% - config.artifact: Artifact definition (Nx2 array or FT structure).
%
% This function segments the data in not necesary consecutive
% (non)overlapping segments of 'segment' seconds length, the first segment
% trying to start in 'begtime'. The segments can not extend beyond
% 'endtime'. All the segments must be surrounded by, at least,
% 'padding' seconds of data.
% 
% The output is a Nx3 matrix, indicating in each row the first sample, the
% last sample and the number of pre-zero samples of a given segment.
% 
% If 'equal' is set to false, the last segment can be shorter than
% 'segment', in order to cover all the data.
% If 'equal' is set to true and 'artifact' is not defined, the last segment
% is over-overlapped with the previous to one segment.
% If 'equal' is set to true and 'artifact' is defined, the last segment is
% discarded if can not be fullfilled with the provided configuration.
% 
% If 'padding' is non-zero and 'addpadd' is set to 'true', segments are
% expanded by 'padding' seconds, and the offset is set accordingly.
% If 'begtime' is smaller than 'padding' its value is set to 'padding' + 1.
% If 'endtime' is greater than data length - 'padding', its value is set to
% data length - 'padding' - 1.
% If 'begtime' or 'endtime' are set to NaN its value is automatically set
% to the most extreme valid values.
% 
% 'artifact' can be a FieldTrip artifact definition structure or a Nx2
% artifact definition, indicating in each row the starting and ending
% sample for a given artifact.
% The samples defined as artifacts are forbidden, and the segmentation is
% performed avoiding them.

% 'dataset' and 'segment' are mandatory fields.
if ~isfield ( cfg, 'dataset' ), error ( 'Not dataset provided,' );        end
if ~isfield ( cfg, 'segment' ), error ( 'Not segment length provided,' ); end

% Initializes the structure fields.
if ~isfield ( cfg, 'header' ),   cfg.header   = ft_read_header ( cfg.dataset ); end
if ~isfield ( cfg, 'begtime' ),  cfg.begtime  = NaN;                            end
if ~isfield ( cfg, 'endtime' ),  cfg.begtime  = NaN;                            end
if ~isfield ( cfg, 'overlap' ),  cfg.overlap  = 0;                              end
if ~isfield ( cfg, 'equal' ),    cfg.equal    = true;                           end
if ~isfield ( cfg, 'padding' ),  cfg.padding  = 0;                              end
if ~isfield ( cfg, 'addpadd' ),  cfg.addpadd  = false;                          end
if ~isfield ( cfg, 'artifact' ), cfg.artifact = zeros ( 0, 2 );                 end


% Stablish the time of interest.
tin   = cfg.begtime;
tf    = cfg.endtime;
ttrl  = cfg.segment;
tpad  = cfg.padding;
tstep = cfg.segment - cfg.overlap;

% Gets the samples related to those times.
sin   = round ( tin   * cfg.header.Fs );
sf    = round ( tf    * cfg.header.Fs );
spad  = round ( tpad  * cfg.header.Fs );
strl  = round ( ttrl  * cfg.header.Fs );
sstep = round ( tstep * cfg.header.Fs );

% Sets the offset to the padding, if it is included in the epoch.
soff  = - spad * cfg.addpadd;

% Gets the artifact samples.
sart  = cfg.artifact;


% If no beggining or ending time, uses the extremes of the data.
if isnan ( sin )
    sin   = spad + 1;
end

if isnan ( sf  )
    sf    = cfg.header.nSamples - spad;
end

% Checks if the beggining and ending times are valid.
if ( sin < spad + 1 )
    warning ( 'restSemgent:endTime', 'The initial time is smaller than the padding.' );
    sin   = spad + 1;
end

if ( sf  > cfg.header.nSamples - spad )
    warning ( 'restSemgent:startTime', 'The final time is greater than the data.' );
    sf    = cfg.header.nSamples - spad;
end




% Converts the artifacts to matrix form, if needed.
if isstruct ( sart )
    sart  = struct2cell ( sart );
    if isstruct ( sart {1} )
        sart = cellfun ( @(artifacts) artifacts.artifact, sart, 'UniformOutput', false );
    end
    
    % Concatenates all the artifacts.
    sart  = cat ( 1, sart {:} );
end

% Sorts the artifact definitions.
sart  = sortrows ( sart );

% Removes the artifacts out of the defined beginning and ending samples.
sart ( sart ( :, 2 ) < sin, : ) = [];
sart ( sart ( :, 1 ) > sf,  : ) = [];
% sart ( sart ( 2, : ) < sin, : ) = [];
% sart ( sart ( 1, : ) > sf,  : ) = [];

% Adds two 'virtual' artifacts at the edges of the data.
sart  = cat ( 1, [ 1 sin - 1 ], sart, [ sf + 1 cfg.header.nSamples ] );


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


% Gets a list of clean segments starts and endings.
sbegs = sart ( :, 2 ) + 1;
sends = sart ( :, 1 ) - 1;

sbegs (end) = [];
sends (1)   = [];


% Reserves memory for the trials.
trl   = cell ( numel ( sbegs ), 1 );

% Goes through each artifact ending.
for sindex = 1: numel ( sbegs )
    
    % If the segment is too short, continues.
    if sends ( sindex ) - sbegs ( sindex ) + 1 < strl, continue, end
    
    % Calculates the number of trials to fit.
    space = ( sends ( sindex ) - sbegs ( sindex ) + 1 );
    ntrl  = floor ( ( space - ( strl - sstep ) ) / sstep );
    trl   { sindex } = zeros ( ntrl, 3 );
    
    % Stores the trials.
    for tindex = 1: ntrl
        
        xtrl  (1) = sbegs ( sindex ) + ( tindex - 1 ) * sstep + soff;
        xtrl  (2) = xtrl (1) + strl - 1 - 2 * soff;
        xtrl  (3) = soff;
        
        trl { sindex } ( tindex, : ) = xtrl;
    end
end

% Concatenates all the trials.
trl   = cat ( 1, trl {:} );


% If no artifact definition, tries to use the whole data.
if isempty ( cfg.artifact ) && trl ( end, 2 ) < sf
    
    % If the segments can have different sizes, shortens the last one.
    if ~cfg.equal
        xtrl  (1) = trl ( end, 1 ) + sstep;
        xtrl  (2) = sf - soff;
        xtrl  (3) = soff;
        
    % If equal segments, shifts the last one.
    else
        xtrl  (1) = sf - strl + soff + 1;
        xtrl  (2) = sf - soff;
        xtrl  (3) = soff;
    end
    
    % Adds the new trial.
    trl = cat ( 1, trl, xtrl );
end
