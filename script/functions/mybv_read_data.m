function data = mybv_read_data ( filename, header, begsample, endsample, channel )

% Based on FieldTrip 20190705 functions:
% * read_brainvision_eeg by Robert Oostenveld.


% Gets the file header, if not provided.
if nargin < 2 || isempty ( header )
    header     = mybv_read_header ( filename );
end

% Gets the raw file header.
info       = header.orig;


% Checks the input.
if nargin < 3
    begsample  = 1;
    endsample  = sum ( info.nSamples );
    channel    = 1: sum ( info.NumberOfChannels );
elseif nargin < 4
    endsample  = sum ( info.nSamples );
    channel    = 1: sum ( info.NumberOfChannels );
elseif nargin < 5
    channel    = 1: sum ( info.NumberOfChannels );
elseif nargin > 5
    error ( 'Incorrect number of arguments' );
end
if begsample > endsample, error ( 'No data in the selected range.' ); end


% Gets the number of channels.
nchan = info.NumberOfChannels;

% Gets the number of samples to read.
nsamp = endsample - begsample + 1;
skip  = nchan * ( begsample - 1 );


% Gets the path to the data file (eeg file).
filepath = fileparts ( filename );
datafile = sprintf ( '%s/%s', filepath, info.DataFile );


% For binary files.
if strcmpi ( info.DataFormat, 'Binary' )
    
    % Gets the sample encoding type and size.
    switch lower ( info.BinaryFormat )
        case 'int_16'
            stype = 'int16';
            ssize = 2;
        case 'int_32'
            stype = 'int32';
            ssize = 4;
        case 'ieee_float_32'
            stype = 'float32';
            ssize = 4;
        otherwise
            error ( 'Unknown data format.' )
    end
    
    
    % Multiplexed data is stored as nchan x nsamp.
    if strcmpi ( info.DataOrientation, 'Multiplexed' )
        
        % Opens the file to read.
        fid   = fopen ( datafile, 'rb', 'ieee-le' );
        
        % Skips the first samples, if requested.
        fseek ( fid, skip * ssize, 'bof');
        
        % Reads the requested samples.
        data  = fread ( fid, [ nchan nsamp ], stype );
        
        % Closes the file.
        fclose ( fid );
        
    % Vectorized data is stored as nsamp x nchan.
    elseif strcmpi ( info.DataOrientation, 'Vectorized' )
        
        % Opens the file to read.
        fid   = fopen ( datafile, 'rb', 'ieee-le' );
        
        % Reads the whole data.
        data  = fread ( fid, [ nsamp nchan ], stype )';
        
        % Selects only the desired data, if requested.
        data  = data ( :, begsample: endsample );
        
        % Closes the file.
        fclose ( fid );
        
    else
        error ( 'Unknown data orientation.' );
    end
    
% For text files.
elseif strcmpi ( info.DataFormat, 'ASCII' )
    
    error ( 'Not yet implemented.' );
    
% elseif strcmpi(hdr.DataFormat, 'ascii') && strcmpi(hdr.DataOrientation, 'multiplexed')
%   fid = fopen ( filename, 'rt' );
%   
%   % skip lines if hdr.skipLines is set and not zero
%   if isfield(hdr,'skipLines') && hdr.skipLines > 0
%     for line=1:hdr.skipLines
%       str = fgets(fid);
%     end;
%   end;
%   
%   for line=1:(begsample-1)
%     % read first lines and discard the data in them
%     str = fgets(fid);
%   end
%   dat = zeros(endsample-begsample+1, hdr.NumberOfChannels);
%   for line=1:(endsample-begsample+1)
%     str = fgets(fid);         % read a single line with Nchan samples
%     str(str==',') = '.';      % replace comma with point
%     dat(line,:) = str2num(str);
%   end
%   fclose(fid);
%   % transpose the data
%   dat = dat';
%   
% elseif strcmpi(hdr.DataFormat, 'ascii') && strcmpi(hdr.DataOrientation, 'vectorized')
%   % this is a very inefficient fileformat to read data from, since it requires to
%   % read in all the samples of each channel and then select only the samples of interest
%   fid = fopen ( filename, 'rt' );
%   dat = zeros(hdr.NumberOfChannels, endsample-begsample+1);
%   skipColumns = 0;
%   for chan=1:hdr.NumberOfChannels
%     % this is very slow, so better give some feedback to indicate that something is happening
%     fprintf('reading channel %d from ascii file to get data from sample %d to %d\n', chan, begsample, endsample);
%     
%     % check whether columns have to be skipped
%     if isfield(hdr,'skipColumns'); skipColumns = hdr.skipColumns; end;
%     
%     str = fgets(fid);             % read all samples of a single channel
%     str(str==',') = '.';          % replace comma with point
%     
%     if ~isempty(regexp(str(1:10), '[a-zA-Z]', 'once'))
%       % the line starts with letters, not numbers: probably it is a channel label
%       % find the first number and remove the preceding part
%       sel   = regexp(str(1:10), ' [-0-9]');   % find the first number, or actually the last space before the first number
%       label = str(1:(sel));                   % this includes the space
%       str   = str((sel+1):end);               % keep only the numbers
%       
%       % as heading columns are already removed, set skipColumns to zero
%       skipColumns = 0;
%     end
%     
%     % convert the string into numbers and copy the desired samples over
%     % into the data matrix
%     tmp = str2num(str);
%     dat(chan,:) = tmp(skipColumns+begsample:skipColumns+endsample);
%   end
%   fclose(fid);
    
else
    error ( 'Unknown data format.' );
end


% Checks if the reference is a channel.
if isfield ( info, 'ref_label' ) && isfield ( info, 'ref_index' )
    
    % Creates a virtual channel for the reference.
    data = data ( [ 1: info.ref_index info.ref_index: end ], : );
    
    % Fills the channel data with zeros.
    data ( info.ref_index, : ) = 0;
    
    % This is not needed; the header contains the reference channel.
%     % Changes the index to the channels to add the new one.
%     % Be careful here...
%     channel = cat ( 2, channel ( 1: info.ref_index - 1 ), info.ref_index, channel ( info.ref_index: end ) + 1 );
end


% Applies the resolution factor to obtain real world units.
data  = bsxfun ( @times, data, info.resolution );

% Selects only the desired channels.
data  = data ( channel, : );
