function event = my_read_event ( filename, header )

% Gets the file header.
if nargin < 2
    header = my_read_header ( filename );
end

% Tries to use the specific function.
if ft_filetype ( filename, 'neuromag_fif' )
    event  = myfiff_read_event ( filename, header );
    
elseif ft_filetype ( filename, 'egi_mff' )
    event  = mymff_read_event ( filename, header );
    
elseif ft_filetype ( filename, 'ns_cnt' )
    event  = mycnt_read_event ( filename, 'header', header );
    
elseif ft_filetype ( filename, 'brainvision_vhdr' ) || ft_filetype ( filename, 'brainvision_eeg' )
    event  = mybv_read_event ( filename, header );
    
% If no specific function relies on FieldTrip.
else
    event  = ft_read_event ( filename );
end


% Sorts the events by sample.
[ ~, sorting ] = sort ( [ event.sample ] );
event  = event ( sorting );
