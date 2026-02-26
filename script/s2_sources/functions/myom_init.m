function myom_init ( deep )

% Function to check that OpenMEEG is installed and accesible.
%
% Based on OpenMEEG functions:
% * om_checkombin by the OpenMEEG developers


% Looks for the OpenMEEG binaries in the path.
if myom_inpath

    % Tries to run the binaries, if found.
    myom_checkbin;
    return
end


% Logic for looking for OpenMEEG in Windows.
if ispc
    
    
    % Looks for a folder named OpenMEEG in C:/Program Files.
    for basedir = { 'C:/Program Files' }
        
        % Looks for an OpenMEEG folder in those locations.
        output = dir ( sprintf ( '%s/OpenMEEG*', basedir {1} ) );
        if isempty ( output ), continue, end
        
        % Lists the candidates.
        candidates = strcat ( basedir {1}, '/', { output.name } );
        
        % Goes through each OpenMEEG folder candidates.
        for candidate = candidates
            
            % Generates the binary folder.
            bindir = sprintf ( '%s/bin', candidate {1} );
    
            % Looks for the OpenMEEG binaries.
            if myom_inpath ( bindir )
    
                % Tries to run the binaries, if found.
                if myom_checkbin ( bindir )
    
                    % If success, adds the folder to the path.
                    myom_addpath ( bindir )
                    
                    % Prints the OpenMEEG location in screen.
                    fprintf ( 1, 'Using OpenMEEG in: %s.\n', bindir )
    
                    % Exists silently.
                    return
                end
            end
        end
    end


% Logic for looking for OpenMEEG in Linux and Mac.
else

    % Looks for the binaries in /bin, /usr/bin, /usr/local/bin, and /opt/bin.
    for candidate = { '/bin', '/usr/bin', '/usr/local/bin', '/opt/bin' }
        
        % Generates the binary folder.
        bindir = candidate {1};
        
        % Looks for the binaries.
        if myom_inpath ( bindir )
        
            % Tries to run the binaries, if found.
            if myom_checkbin ( bindir )
                
                % If success, adds the folder to the path.
                myom_addpath ( bindir )
                
                % Prints the OpenMEEG location in screen.
                fprintf ( 1, 'Using OpenMEEG in: %s.\n', bindir )
                
                % Exists silently.
                return
            end
        end
    end
    
    
    % Looks for a folder named OpenMEEG in /usr, /usr/local, and /opt.
    for basedir = { '/usr', '/usr/local', '/opt' }
        
        % Looks for an OpenMEEG folder in those locations.
        [ status, output ] = system ( sprintf ( 'find %s/* -maxdepth 0 -iname "openmeeg*"', basedir {1} ) );
        if status ~= 0, continue, end
        if isempty ( output ), continue, end
        
        % Lists the candidates.
        candidates = splitlines ( strtrim ( output ) )';
        
        % Goes through each OpenMEEG folder candidates.
        for candidate = candidates
            
            % Generates the binary folder.
            bindir = sprintf ( '%s/bin', candidate {1} );
    
            % Looks for the OpenMEEG binaries.
            if myom_inpath ( bindir )
    
                % Tries to run the binaries, if found.
                if myom_checkbin ( bindir )
    
                    % If success, adds the folder to the path.
                    myom_addpath ( bindir )
                    
                    % Prints the OpenMEEG location in screen.
                    fprintf ( 1, 'Using OpenMEEG in: %s.\n', bindir )
    
                    % Exists silently.
                    return
                end
            end
        end
    end
    
    
    % If deep search, does in intensive search for the binaries.
    if nargin && deep
        
        % Looks for the binaries in /usr and /opt.
        for basedir = { '/usr', '/opt' }
            
            % Looks for the OpenMEEG binaries.
            [ ~, output ] = system ( sprintf ( 'find %s/* -name om_assemble 2>/dev/null', basedir {1} ) );
            if isempty ( output ), continue, end
    
            % Lists the candidates.
            candidates = splitlines ( strtrim ( output ) )';
    
            % Goes through each OpenMEEG folder candidates.
            for candidate = candidates
                
                % Gets the folder.
                bindir = fileparts ( candidate {1} );
    
                % Tries to run the binaries, if found.
                if myom_checkbin ( bindir )
    
                    % If success, adds the folder to the path.
                    myom_addpath ( bindir )
                    
                    % Prints the OpenMEEG location in screen.
                    fprintf ( 1, 'Using OpenMEEG in: %s.\nPlease, add it to the system search path.\n', bindir )
    
                    % Exists silently.
                    return
                end
            end
        end
    end
end


% If Windows, raises an specific error.
if ispc
    error ( [
        'OpenMEEG is not installed or not in the path.\n' ...
        'Please, follow the instructions in:\n' ...
        '%s' ], 'https://www.fieldtriptoolbox.org/faq/source/openmeeg/#installation-procedure-for-windows' )
end

% If not found, raises an error.
error ( [
    'OpenMEEG is not installed, or not in the system path.\n' ...
    'The search path includes folders:\n' ...
    '  %s' ], getenv ( 'PATH' ) )



function result = myom_checkbin ( ompath )

% If no provided path for OpenMEEG, uses the current search path.
if nargin == 0, ompath = ''; end

% Tries to run OpenMEEG binaries.
if ispc
    [ status, msg ] = system ( sprintf ( 'PATH=%%PATH%%;%s; && om_assemble', ompath ) );
else
    [ status, msg ] = system ( sprintf ( 'export PATH="%s:$PATH"; om_assemble', ompath ) );
end

% If success or probing a new path, returns the result.
if status == 0 || nargin > 0
    result = ( status == 0 );
    return
end

% Otherwise, raises an error.
if nargin == 0
    error ( [ ...
        'OpenMEEG could not run:\n' ...
        '%s' ], msg )
end


function result = myom_inpath ( ompath )

% If no provided path for OpenMEEG, uses the current search path.
if nargin == 0, ompath = ''; end

% Looks for the OpenMEEG binaries.
if ispc
    [ status, ~ ] = system ( sprintf ( 'PATH=%%PATH%%;%s; && where om_assemble', ompath ) );
else
    [ status, ~ ] = system ( sprintf ( 'export PATH="%s:$PATH"; which om_assemble', ompath ) );
end

result = ( status == 0 );



function myom_addpath ( basedir )
% Adds the OpenMEEG folder(s) to the path.

% Gets the provided folder and its path.
[ prevdir, lastdir ] = fileparts ( basedir );

% If it is a binaries folder (bin) uses bin and lib.
if strcmp ( lastdir, 'bin' )
    bindir = sprintf ( '%s/%s', prevdir, 'bin' );
    libdir = sprintf ( '%s/%s', prevdir, 'lib' );
    
% Otherwise uses only the provided folder.
else
    bindir = basedir;
    libdir = basedir;
end


% Adds the binary folder.
if ispc
    setenv ( 'PATH', sprintf ( '%s;%s;', getenv ( 'PATH' ), bindir ) )
else
    setenv ( 'PATH', sprintf ( '%s:%s', getenv ( 'PATH' ), bindir ) )
end

% Adds the library folder.
if isunix
    setenv ( 'LD_LIBRARY_PATH', sprintf ( '%s:%s', getenv ( 'LD_LIBRARY_PATH' ), libdir ) )
elseif ismac
    setenv ( 'DYLD_LIBRARY_PATH', sprintf ( '%s:%s', getenv ( 'DYLD_LIBRARY_PATH' ), libdir ) )
end
