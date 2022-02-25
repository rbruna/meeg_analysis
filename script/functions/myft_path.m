function myft_path

% Search for a version of FiedlTrip in the path.
if ~isempty ( which ( 'ft_defaults' ) ), return, end

% Looks for FieldTrip in the parent folder.
ft_path = dir ( sprintf ( '%s/fieldtrip*', fileparts ( pwd ) ) );
ft_path = ft_path ( [ ft_path.isdir ] );

% Adds, if any version, FieldTrip to the path.
if numel ( ft_path )
    addpath ( sprintf ( '%s/%s/', fileparts ( pwd ), ft_path ( end ).name ) )
    
% Otherwise exits with an error.
else
    error ( 'preproc:NoFT', 'No FieldTrip version neither in your path nor in the parent of the current folder.\nThis script cannot continue.' )
end

% Initializes the FieldTrip setup.
ft_defaults

% Disables the FT feedback.
global ft_default;
ft_default.showcallinfo = 'no';
ft_default.checkconfig  = 'silent';
