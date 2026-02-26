function level = myom_verbosity ( newlevel )

% Gets or defines the persistent variable.
persistent oldlevel
if isempty ( oldlevel ), oldlevel = inf; end

% Sets or updates the verbosity level, if requested.
if nargin, oldlevel = newlevel; end
    
% Returns the current verbosity level, if requested.
if nargout > 0, level = oldlevel; end
