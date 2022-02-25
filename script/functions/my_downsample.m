function data = my_downsample ( data, factor )

% Downsamples both data and trime by the given factor.
data.trial        = celldownsample ( data.trial, factor );
data.time         = celldownsample ( data.time,  factor );

% Converts the trial definition into double, if required.
data.sampleinfo   = double ( data.sampleinfo );

% Calculates the new trial length.
triallen          = floor ( diff ( data.sampleinfo, [], 2 ) / factor ) + 1;

% Modifies the trial definition.
data.sampleinfo ( :, 1 ) = ceil ( data.sampleinfo ( :, 1 ) / factor );
data.sampleinfo ( :, 2 ) = data.sampleinfo ( :, 1 ) + triallen - 1;

% Modifies the metadata.
data.fsample      = data.fsample / factor;

% Modifies the header, if any.
if isfield ( data, 'hdr' )
    data.hdr.Fs       = data.hdr.Fs / factor;
    data.hdr.nSamples = floor ( data.hdr.nSamples / factor );
end

function data = celldownsample ( data, factor )

if isscalar ( factor ), factor = repmat ( { factor }, size ( data ) ); end

data = cellfun ( @(data,factor) data ( :, 1: factor: end ), data, factor, 'UniformOutput', false );
