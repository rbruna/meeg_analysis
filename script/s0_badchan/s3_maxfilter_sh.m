clc
clear
close all

% The input structure must be an array of structures named 'files' with the
% fields:
%   
%   files.file    - The name of the file.
%   files.bad     - The list of bad channels (optional).
%   files.trans   - The file to which transform the back projection specific for this file (optional).
%   files.cal     - The file calibration file specific for this file (optional).
%   files.ctc     - The cross-talk correction file specific for this file (optional).
%   files.logfile - The log file specific for this file (optional).
%   files.errfile - The error file specific for this file (optional).

% Name of the files' structure file.
input    = '../../meta/badchannels.mat';

% Folder options.
indir    = '/neuro/data/Current_github/data/raw/';
outdir   = '/neuro/data/Current_github/data/tsss/';
logdir   = '/neuro/data/Current_github/data/tsss/';

% Computer where the Maxfilter is going to be applied ('elekta' or other).
computer = '';

% MaxFilter options (first run).
configs (1).inner    = 8;           % SSS inner expansion order.      Between 5 and 11 (default 8)
configs (1).outter   = 3;           % SSS outter expansion order.     Between 1 and 5 (default 3)
configs (1).autobad  = false;       % Autobad detection.              Number of seconds (default 60)
configs (1).tsss     = 10;          % tSSS window.                    Number of seconds (default 10) or false
configs (1).corr     = .9;          % Correlation limit.              Between 0.90 and 0.98 (default 0.98)

configs (1).frame    = 'head';      % Coordinates frame.              'head' or 'device' (default 'head')
configs (1).ori      = true;        % Fit origin to IsoTrak.          true or false (default false)
configs (1).ori_fix  = [ 0 0 0 ];   % Origin compensation.            Three elements vector

configs (1).trans    = false;       % Position correction.            'default' or filename (default 'initial')
configs (1).movecomp = true;        % Movement compensarion.          true or false (default false)
configs (1).hpicons  = true;        % Uses the Isotrack check.        true or false (default false)
configs (1).hpiwin   = 200;         % Length of the sliding window.   Number of ms (default 200)
configs (1).hpistep  = 10;          % Step for the sliding window.    Number of ms (default 10)
configs (1).hpisubt  = 'off';       % HPI coils signal removed.       'amp', 'line' or 'off' (default 'amp');
configs (1).hpfile   = false;       % File to store head positions.   String (default original filename with extension '.pos')

configs (1).cal      = '/neuro/databases/sss/sss_cal_20120831.dat'; % Fine calibration file
configs (1).ctc      = '/neuro/databases/ctc/ct_sparse_orion.fif'; % Crosstalk correction file

configs (1).force    = true;        % Ignore warnings.                true or false (default false)
configs (1).format   = 'float';     % Output format.                  'float', 'long' or 'short' (default 'float')
configs (1).outname  = '';          % Filename appendix.              String (default depending on the options)
configs (1).logfile  = false;       % Global log file name.           String (default original filename with extension '.log')
configs (1).errfile  = false;       % Global error file name.         String (default original filename with extension '.err')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%% End of the configurable area. %%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% Loads the bad channels and the file specific options list.
files = struct2array ( load ( input ) );

% Inits the file.
sh_file = fopen ( 'badchannels.sh', 'w' );
fprintf ( sh_file, '#!/bin/sh \n\n' );

% Creates the log and output folders.
fprintf ( sh_file, '# Creates the output and log folders \n' );
fprintf ( sh_file, 'mkdir %s 2> /dev/null \n', outdir );
fprintf ( sh_file, 'mkdir %s 2> /dev/null \n', logdir );
fprintf ( sh_file, '\n\n\n' );


% Goes through each file.
for file = 1: numel ( files )
    
    % Gets the specific configuration for the current file.
    fconfig = files ( file );
    
    % Checks the integrity of the file configuration structure.
    if ~isfield ( fconfig, 'bad' ),     fconfig.bad     = false; end
    if ~isfield ( fconfig, 'trans' ),   fconfig.trans   = false; end
    if ~isfield ( fconfig, 'cal' ),     fconfig.cal     = false; end
    if ~isfield ( fconfig, 'ctc' ),     fconfig.ctc     = false; end
    if ~isfield ( fconfig, 'logfile' ), fconfig.logfile = false; end
    if ~isfield ( fconfig, 'errfile' ), fconfig.errfile = false; end
    
    % Gets the file name.
    filename = fconfig.file;
    
    % Informs of the file name.
    fprintf ( sh_file, '# Processing file %s%s.fif \n', indir, filename );
    fprintf ( sh_file, '\n' );
    
    % Prints the filename in screen.
    fprintf ( sh_file, 'echo Processing file\\: %s \n', filename );
    fprintf ( sh_file, '\n' );
    
    % Creates an execution for each configuration.
    for index = 1: numel ( configs )
        
        config = configs ( index );
        
        % Sets the output filename according to the options.
        if isequal ( config.outname, false )
            outname = sprintf   ( '%s %s %s %s %s %s_tsss', filename, command.tsss, command.corr, command.frame, command.trans, command.format );
            outname = regexprep ( outname, '[ ]{2,}', ' ' );
            outname = strrep    ( outname, ' -', '_' );
            outname = strrep    ( outname, ' ', '-' );
        else
            outname = sprintf   ( '%s%s', filename, config.outname );
        end
        
        % Sets the head position file according to the configuration.
        if ~config.hpfile
            hpfile  = sprintf ( '%s.pos', filename );
        end
        
        % Sets the log file according to the configuration.
        if config.logfile
            logfile = config.logfile;
        else
            logfile = sprintf ( '%s.log', filename );
        end
        
        % Sets the error file according to the configuration.
        if config.errfile
            errfile = config.errfile;
        else
            errfile = sprintf ( '%s.err', filename );
        end
        
        % If no movement compensation, removes the HPI options.
        if ~config.movecomp
            config.hpiwin  = false;
            config.hpistep = false;
            config.hpisubt = false;
            hpfile         = false;
        end
        
        % Fills the command line options from the configuration structure.
        command.inner    = '';
        command.outter   = '';
        command.autobad  = '-autobad no';
        command.tsss     = '';
        command.corr     = '';
        command.frame    = '';
        command.ori      = '';
        command.trans    = '';
        command.cal      = '';
        command.ctc      = '';
        command.force    = '';
        command.format   = '';
        command.movecomp = '';
        command.hpicons  = '';
        command.hpiwin   = '';
        command.hpistep  = '';
        command.hpisubt  = '';
        
        % Overwrites the configuration with that from the file structure.
        if any ( fconfig.bad ),     config.bad       = sprintf ( '%d ',           fconfig.bad );     end
        
        if any ( fconfig.trans ),   config.trans     = sprintf ( '%s%s', indir,   fconfig.trans );   end
        if any ( fconfig.cal ),     config.cal       = fconfig.cal;                                  end
        if any ( fconfig.ctc ),     config.ctc       = fconfig.ctc;                                  end
        
        if any ( fconfig.logfile ), config.logfile   = sprintf ( '%s%s', logdir,  fconfig.logfile ); end
        if any ( fconfig.errfile ), config.errfile   = sprintf ( '%s%s', logdir,  fconfig.errfile ); end
        
        % Rewrites the parameters as command line arguments.
        if any ( config.inner ),    command.inner    = sprintf ( '-in %d',        config.inner );    end
        if any ( config.outter ),   command.outter   = sprintf ( '-out %d',       config.outter );   end
        if any ( config.autobad ),  command.autobad  = sprintf ( '-autobad %d',   config.autobad );  end
        if any ( config.tsss ),     command.tsss     = sprintf ( '-st %d',        config.tsss );     end
        if any ( config.corr ),     command.corr     = sprintf ( '-corr %.3f',    config.corr );     end
        if any ( config.frame ),    command.frame    = sprintf ( '-frame %s',     config.frame );    end
        if any ( config.ori ),      command.ori      = sprintf ( '-origin $a1 $a2 $a3' );            end
        if any ( config.trans ),    command.trans    = sprintf ( '-trans %s.fif', config.trans );    end
        if any ( config.cal ),      command.cal      = sprintf ( '-cal %s',       config.cal );      end
        if any ( config.ctc ),      command.ctc      = sprintf ( '-ctc %s',       config.ctc );      end
        if any ( config.force ),    command.force    = sprintf ( '-force' );                         end
        if any ( config.format ),   command.format   = sprintf ( '-format %s',    config.format );   end
        
        % Gets the movement compensation options.
        if any ( config.movecomp ), command.movecomp = sprintf ( '-movecomp inter' );                end
        if any ( config.hpicons ),  command.hpicons  = sprintf ( '-hpicons' );                       end
        if any ( config.hpiwin ),   command.hpiwin   = sprintf ( '-hpiwin %i',    config.hpiwin  );  end
        if any ( config.hpistep ),  command.hpistep  = sprintf ( '-hpistep %i',   config.hpistep );  end
        if any ( config.hpisubt ),  command.hpisubt  = sprintf ( '-hpisubt %s',   config.hpisubt );  end
        
        % Gets the list of bad channels for the current file.
        if config.bad
            command.bad = sprintf ( '-bad %s ', config.bad );
        end
        
        
        % Prints the date and input file and the bad channels in the log file.
        fprintf ( sh_file, 'date +''%%d/%%m/%%Y %%H:%%M:%%S.%%N'' >> %s%s \n',    logdir, logfile  );
        fprintf ( sh_file, 'echo Processing file\\: %s >> %s%s \n', filename,     logdir, logfile  );
        fprintf ( sh_file, 'echo Bad channels\\: %s >> %s%s \n',    config.bad,   logdir, logfile  );
        fprintf ( sh_file, 'echo >> %s%s \n',                                     logdir, logfile  );
        fprintf ( sh_file, '\n' );
        
        % Prints the date and input file in the error file.
        fprintf ( sh_file, 'date +''%%d/%%m/%%Y %%H:%%M:%%S.%%N'' >> %s%s \n',    logdir, errfile  );
        fprintf ( sh_file, 'echo Processing file\\: %s >> %s%s \n', filename,     logdir, errfile  );
        fprintf ( sh_file, 'echo >> %s%s \n',                                     logdir, errfile  );
        fprintf ( sh_file, '\n' );
        
        % If origin, prints the lines to get the best-fitting center.
        if config.ori
            
            % Gets the best fitting center.
            fprintf ( sh_file, 'a=`nice /neuro/bin/util/maxfilter -gui ' );
            fprintf ( sh_file, '-f %s%s.fif -origin fit -frame head` \n',         indir,  filename );
            
            % Extracts the x, y and z points with a regular expression.
            if strcmp ( computer, 'elekta' )
                fprintf ( sh_file, '[[ $a =~ \\#o\\ head\\ \\(-?[0-9\\.]+\\)\\ \\(-?[0-9\\.]+\\)\\ \\(-?[0-9\\.]+\\)\\ mm ]] \n' );
            else
                fprintf ( sh_file, '[[ $a =~ \\#o\\ head\\ (-?[0-9\\.]+)\\ (-?[0-9\\.]+)\\ (-?[0-9\\.]+)\\ mm ]] \n' );
            end
            fprintf ( sh_file, 'a1=${BASH_REMATCH[1]}; a2=${BASH_REMATCH[2]}; a3=${BASH_REMATCH[3]} \n' );
            fprintf ( sh_file, '\n' );
            
            % Stores the origin in the log file.
            fprintf ( sh_file, 'echo Origin found in $a1 $a2 $a3 >> %s%s \n',     logdir, logfile  );
            
            % If the origin must be corrected, applies the correction.
            if any ( config.ori_fix )
                
                % Corrects the position of the center.
                fprintf ( sh_file, '\n' );
                fprintf ( sh_file, 'a1=`echo $a1%+.1f | bc`; a2=`echo $a2%+.1f | bc`; a3=`echo $a3%+.1f | bc` \n', config.ori_fix );
                fprintf ( sh_file, '\n' );
                
                % Stores the new origin in the log file.
                fprintf ( sh_file, 'echo Origin moved to $a1 $a2 $a3 >> %s%s \n', logdir, logfile  );
            end
            
            % Prints a blank line in the log file.
            fprintf ( sh_file, 'echo >> %s%s \n',                                 logdir, logfile  );
            fprintf ( sh_file, '\n' );
        end
        
        % Calls maxfilter.
        fprintf ( sh_file, 'nice /neuro/bin/util/maxfilter -gui ' );
        fprintf ( sh_file, '-f %s%s.fif ', indir,  filename );
        fprintf ( sh_file, '-o %s%s.fif ', outdir, outname );
        
        % Sets the defined options.
        fprintf ( sh_file, '%s ', command.inner,   command.outter  );
        fprintf ( sh_file, '%s ', command.cal,     command.ctc     );
        fprintf ( sh_file, '%s ', command.autobad, command.bad     );
        fprintf ( sh_file, '%s ', command.tsss,    command.corr    );
        fprintf ( sh_file, '%s ', command.ori,     command.frame   );
        fprintf ( sh_file, '%s ', command.trans,   command.hpicons );
        fprintf ( sh_file, '%s ', command.format,  command.force   );
        
        % Sets the movement compensation options.
        fprintf ( sh_file, '%s ', command.movecomp, command.hpiwin,   command.hpistep  );
        
        % Sets the movement compensation file.
        if any ( hpfile ),  fprintf ( sh_file, '-hp %s%s ', logdir, hpfile  ); end
        
        % Sets the log options.
        if any ( logfile ), fprintf ( sh_file, '1>> %s%s ', logdir, logfile ); end
        if any ( errfile ), fprintf ( sh_file, '2>> %s%s ', logdir, errfile ); end
        fprintf ( sh_file, '\n\n' );
        
        % Prints two blank lines in the log file.
        fprintf ( sh_file, 'echo >> %s%s \n', logdir, logfile );
        fprintf ( sh_file, 'echo >> %s%s \n', logdir, logfile );
        fprintf ( sh_file, '\n' );
        
        % Prints two blank lines in the error file.
        fprintf ( sh_file, 'echo >> %s%s \n', logdir, errfile );
        fprintf ( sh_file, 'echo >> %s%s \n', logdir, errfile );
        fprintf ( sh_file, '\n\n' );
        
    end
    
    fprintf ( sh_file, '\n' );
end

fclose ( sh_file );
