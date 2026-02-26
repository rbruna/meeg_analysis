function mri = my_packmri ( mri )

% Gets the list of fields in the MRI.
fields = fieldnames ( mri );
fields = setdiff ( fields, { 'dim', 'anatomy', 'transform', 'unit', 'coordsys' } );

% Goes through each field.
for findex = 1: numel ( fields )
    
    % Gets the current field name.
    field = fields { findex };
    
    % Checks if the field is a data field.
    if ~isequal ( size ( mri.( field ) ( :, :, :, 1 ) ), mri.dim )
        continue
    end
    
    % Checks if the data can be set as 8-bit.
    if ...
            isfloat ( mri.( field ) ) && ...
            all ( mri.( field ) (:) >= 0 ) && ...
            all ( mri.( field ) (:) <= 1 ) && ...
            all ( mri.( field ) (:) * 255 - round ( mri.( field ) (:) * 255 ) < 1e-6 )
        
        % Transforms the data to unsigned integer of 8 bit.
        mri.( field ) = uint8 ( mri.( field ) * 255 );
        
        continue
    end
    
    % Packs the masks as binary image.
    if ...
            islogical ( mri.( field ) ) && ...
            strcmp ( field, 'mask' )
        
        % Transforms the data to packed image.
        mri.( field ) = bwpack ( mri.( field ) ( :, : ) );
        
        continue
    end
end
