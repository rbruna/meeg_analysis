function files = my_deepfind ( base, pattern, maxit )


% Sets the default iteration limit to 20.
if nargin < 3
    maxit  = 20;
end


% Adds a slash to the end of the base folder, if required.
if ~strcmp ( base ( end ), '/' )
    base   = strcat ( base, '/' );
end


% Looks for files matching the pattern.
hits   = dir ( sprintf ( '%s%s', base, pattern ) );
hits   = hits ( ~[ hits.isdir ] );

% Gets the file names.
fname  = { hits.name };

% Creates a files structure.
files  = struct ( 'name', fname, 'folder', base );
files  = files (:);


% If the iteration limit is reached returns.
if maxit < 1
    warning ( 'Maximum number of iterations reached.' )
    return
end


% Looks for subfolders.
hits   = dir ( base );
hits   = hits ( [ hits.isdir ] );
hits   = hits ( 3: end );

% Goes thfough each subfolder.
for hindex = 1: numel ( hits )
    
    % Calls the function iteratively.
    sfiles = my_deepfind ( sprintf ( '%s%s', base, hits ( hindex ).name ), pattern, maxit - 1 );
    
    % Adds the new files.
    files  = cat ( 1, files, sfiles );
end
