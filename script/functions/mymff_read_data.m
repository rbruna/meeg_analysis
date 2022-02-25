function data = mymff_read_data ( filename, header, sbeg, send, chan )

% Based on FieldTrip functions:
% * read_mff_bin
% * read_mff_block


% Gets the file header, if needed.
if nargin < 2 || isempty ( header )
    header     = mymff_read_header ( filename );
end
info       = header.orig;

% Checks the input.
if nargin < 3
    sbeg       = 1;
    send       = sum ( info.nsample );
    chan       = 1: sum ( info.nchannel );
elseif nargin < 4
    send       = sum ( info.nsample );
    chan       = 1: sum ( info.nchannel );
elseif nargin < 5
    chan       = 1: sum ( info.nchannel );
elseif nargin > 5
    error ( 'Incorrect number of arguments' );
end
if sbeg > send, error ( 'No data in the selected range.' ); end
nchan      = numel ( chan );


% Updates the raw data information.
rawinfos   = mymff_read_info ( filename );
rawheaders = cat ( 1, rawinfos.rawinfo.header );
bstart     = cat ( 1, rawheaders.blockstart );
bstart     = reshape ( bstart, size ( rawheaders ) );
bend       = cumsum ( rawinfos.nsample );
bbeg       = bend - rawinfos.nsample + 1;

% Gets an array of signal-wise channel indexes.
schan      = zeros ( sum ( rawinfos.nchannel ), 2 );
for sindex = 1: numel ( rawinfos.nchannel )
    cindex     = 1: rawinfos.nchannel ( sindex );
    cshift     = sum ( rawinfos.nchannel ( 1: sindex - 1 ) );
    schan ( cindex + cshift, 1 ) = cindex;
    schan ( cindex + cshift, 2 ) = sindex;
end
schan      = schan ( chan, : );
chan       = cat ( 2, chan (:), schan );
signals    = unique ( chan ( :, 3 ) );

% List the blocks to read.
first      = find ( bbeg <= sbeg, 1, 'last' );
last       = find ( bend >= send, 1, 'first' );
fbeg       = bbeg ( first );
fend       = bend ( last );


% Reserves memory for the data.
data       = zeros ( nchan, fend - fbeg + 1 );

% Goes through each signal file.
for sindex = signals'
    
    % Opens the file to read.
    fid = fopen ( rawinfos.rawinfo ( sindex ).filename, 'rb' );
    
    % Reads all the blocks to the data matrix.
    for bindex = first: last
        
        % Gets the current block information.
        rawheader  = rawheaders ( sindex, bindex );
        rawdata    = zeros ( rawheader.nsignals, rawheader.nsamples (1) );
        
        % Goes to the current block and skips the header.
        fseek ( fid, bstart ( sindex, bindex ), 'bof' );
        fseek ( fid, rawheader.headersize, 'cof' );
        
        % Reads the channel one by one (could have different precission).
        for cindex = 1: rawheader.nsignals
            
            % Gets the precission.
            switch rawheader.depth ( cindex )
                case 16, precission = 'int16';
                case 32, precission = 'single';
                case 64, precission = 'double';    
                otherwise, error ( 'Unknown precission.' )
            end
            
            % Reads the channel data, if requested.
            if ismember ( [ cindex sindex ], chan ( :, 2: 3 ), 'rows' )
                rawdata ( cindex, : ) = fread ( fid, rawheader.nsamples (1), precission );
            
            % Skips the channel otherwise.
            else
                fseek ( fid, rawheader.depth ( cindex ) / 8 * rawheader.nsamples (1), 'cof' );
            end
        end
        
        % Gets the data-based position of the block.
        dbeg       = bbeg ( bindex ) - bbeg (1) + 1;
        dend       = bend ( bindex ) - bbeg (1) + 1;
        
        data ( chan ( :, 3 ) == sindex, dbeg: dend ) = rawdata ( chan ( chan ( :, 3 ) == sindex, 2 ), : );
    end
end

% Removes the extra samples.
data ( :, 1: sbeg - fbeg ) = [];
data ( :, send + 1 - fbeg + 1: end  ) = [];

%     % check if requested data contains multiple epochs and not segmented. If so, give error
%     if isfield(hdr.orig.xml,'epochs') && length(hdr.orig.xml.epochs) > 1
%       if hdr.nTrials ==1
%         data_in_epoch = zeros(1,length(hdr.orig.xml.epochs));
%         for iEpoch = 1:length(hdr.orig.xml.epochs)
%           begsamp_epoch = hdr.orig.epochdef(iEpoch,1);
%           endsamp_epoch = hdr.orig.epochdef(iEpoch,2);
%           data_in_epoch(iEpoch) = length(intersect(begsamp_epoch:endsamp_epoch,begsample:endsample));
%         end
%         if sum(data_in_epoch>1) > 1
%           warning('The requested segment from %i to %i is spread out over multiple epochs with possibly discontinuous boundaries', begsample, endsample);
%         end
%       end
%     end
    
%     % Segments the data in trials.
%     if hdr.nTrials > 1
%       dat2=zeros(hdr.nChans,hdr.nSamples,hdr.nTrials);
%       for i=1:hdr.nTrials
%         dat2(:,:,i)=dat(:,hdr.orig.epochdef(i,1):hdr.orig.epochdef(i,2));
%       end;
%       dat=dat2;
%     end

% Applies the calibration and scaling factors to the data.
data      = bsxfun ( @times, info.chan.calib ( chan ( :, 1 ) ), data );

% Transforms the data to single precission to save space.
data      = single ( data );
