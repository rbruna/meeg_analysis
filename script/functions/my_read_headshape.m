function headshape = my_read_headshape ( filename, header )

% BrainVision file format includes no headshape information.
if ft_filetype ( filename, 'brainvision_vhdr' ) || ft_filetype ( filename, 'brainvision_eeg' )
    headshape = [];
    return
end

% NeuroScan NSC file format includes no headshape information.
if ft_filetype ( filename, 'ns_cnt' )
    headshape = [];
    return
end


% If FIFF file, reads the head shape.
if ft_filetype ( filename, 'neuromag_fif' )
    
    % Reads the file header, if not provided.
    if nargin < 2
        header = ft_read_header ( filename );
    end
    
    % Generates the head shape.
    headshape = myfiff_read_headshape ( filename, header );
    return
end


% If not known file format, relies on FieldTrip.
try
    headshape = ft_read_headshape ( filename );
catch
    headshape = [];
end
