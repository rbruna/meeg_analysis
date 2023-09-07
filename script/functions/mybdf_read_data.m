function data = mybdf_read_data ( filename, header, begsample, endsample, channel )

% Based on functions:
% * read_biosemi_bdf by Robert Oostenveld.


% Reads the header, if not provided.
if nargin < 2
    header = mybdf_read_header ( filename );
end

% Sets the default options.
if nargin < 3
    begsample = 1;
end
if nargin < 4
    endsample = header.nSamples;
end
if nargin < 5
    channel   = 1: header.nChans;
end


% Gets the original header
EDF = header.orig;

% determine the trial containing the begining and ending samples.
elength    = EDF.duration * EDF.channels (1).srate;
begepoch   = floor ( ( begsample - 1 ) / elength ) + 1;
endepoch   = floor ( ( endsample - 1 ) / elength ) + 1;
nepoch     = endepoch - begepoch + 1;
nchan      = EDF.nchannel;


% The code is not tested for epochs larger than 1 sample.
if elength > 1
    warning ( '% Be careful. This code is not tested for epochs larger than 1 sample.' )
end


% % Version 1.
% 
% % Reserves memory for the data.
% data = zeros ( length ( channel ), nepoch * elength );
% 
% % Opens the file to read.
% fid = fopen ( dataset, 'rb', 'ieee-le');
% 
% for eindex = begepoch: endepoch
%     
%     % Goes to the current epoch.
%     offset = EDF.HeadLen + ( eindex - 1 ) * elength * nchan * 3;
%     fseek ( fid , offset, 'bof' );
%     
%     % Reads the epoch.
%     [ buf, num ] = fread ( fid, elength * nchan, 'bit24=>double' );
%     
%     % Checks that the epoch is complete.
%     if num < ( elength * nchan )
%         fprintf ( 'Asked: %i.\nRead:  %i.\n\n', elength * nchan, num );
%         break
%     end
%     
%     % Reshapes the epoch into the right shape (which is not required).
%     buf = reshape ( buf, elength, nchan );
%     
%     % Stores the epoch, if complete.
%     data ( :, ( ( eindex - begepoch ) * elength + 1 ): ( ( eindex - begepoch + 1 ) * elength ) ) = buf';
% end
% 
% % Closes the file.
% fclose ( fid );
% 
% 
% % Applies the calibration and offset values.
% data = EDF.Cal (:) .* data + EDF.Off (:);
% 
% 
% % Keeps only the requested data.
% begindex = round ( begsample - ( begepoch - 1 ) * elength );
% endindex = round ( endsample - ( begepoch - 1 ) * elength );
% data = data ( channel, begindex: endindex );


% Opens the file to read.
fid = fopen ( filename, 'rb', 'ieee-le');

% Goes to the begining of the requested data.
offset = EDF.hdrlen + ( begepoch - 1 ) * elength * nchan * 3;
% offset = EDF.HeadLen + ( begepoch - 1 ) * elength * nchan * 3;
fseek ( fid , offset, 'bof' );

% Reads as many epochs as required.
% [ data, num ] = fread ( fid, nchans * epochlength * nepochs, 'bit24=>double' );
[ data, num ] = fread ( fid, [ elength * nchan nepoch ], 'bit24=>double' );

% Closes the file.
fclose ( fid );


% If the file is incomplete fills the data with zeros.
if num < nchan * elength * nepoch
    warning ( 'File is broken. Only the first %i samples (out of %i) are valid.', floor ( num / nchan ), elength * nepoch )
    data ( elength * nchan, nepoch ) = 0;
end

% Reshapes the data into the correct shape.
data = reshape ( data, [ elength nchan nepoch ] );
data = permute ( data, [ 2 1 3 ] );
data = reshape ( data, nchan, [] );


% Applies the calibration and offset values.
data = [ EDF.channels.calib ]' .* data + [ EDF.channels.offset ]';


% Keeps only the requested data.
begindex = begsample - ( begepoch - 1 ) * elength;
endindex = endsample - ( begepoch - 1 ) * elength;
data = data ( channel, begindex: endindex );
