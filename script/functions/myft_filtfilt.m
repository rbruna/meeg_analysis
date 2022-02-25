function data = myft_filtfilt ( b, a, data, hilbert )

% If empty, sets the 'perform Hilbert filtering' to false variable.
if nargin < 4, hilbert = false; end

data = ft_checkdata ( data, 'datatype', 'raw' );

for trial = 1: numel ( data.trial )
    data.trial { trial } = my_filtfilt ( b, a, data.trial { trial }.', hilbert ).';
end
