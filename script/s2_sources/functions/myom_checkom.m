function varargout = myom_checkom ( desired )

% Checks whether OpenMEEG is installed, and the version is correct.


% Checks that OpenMEEG is installed and the binaries are valid.
myom_init


% Gets the OpenMEEG version, if required.
if nargin > 0 || nargout > 0
    [ ~, out ] = system ( 'om_assemble' );
    hits = regexp ( out, '^om_assemble version ([0-9]+\.[0-9]+).*', 'tokens' );
    version = hits {1} {1};
end

% Compares the OpenMEEG version with the desired one, if provided.
if nargin > 0 && ~strcmp ( version, desired )
    error ( 'These MATLAB functions require OpenMEEG version %s, but version %s is installed.', desired, version )
end

% Returns the OpenMEEG version, if requested.
if nargout
    varargout {1} = version;
end
