function mri = my_unpackmri ( mri )

% Gets the list of fields in the MRI.
fields = fieldnames ( mri );
fields = setdiff ( fields, { 'dim', 'anatomy', 'transform', 'unit', 'coordsys' } );

% Goes through each field.
for findex = 1: numel ( fields )
    
    % Gets the current field name.
    field = fields { findex };
    
    % Checks if the data is 8-bit.
    if isa ( mri.( field ), 'uint8' )
        
        % Transforms the data to single.
        mri.( field ) = single ( mri.( field ) ) / 255;
        
        continue
    end
    
    % Unpacks the masks.
    if ...
            isa ( mri.( field ), 'uint32' ) && ...
            size ( mri.( field ), 1 ) == ceil ( mri.dim (1) / 32 ) && ...
            rem ( size ( mri.( field ), 2 ), mri.dim (2) * mri.dim (3) ) == 0 && ...
            strcmp ( field, 'mask' )
        
        % Transforms the data to single.
        mri.( field ) = bwunpack ( mri.( field ) ( :, : ) );
        
        % Reshapes the data to is original form.
        mri.( field ) = reshape ( mri.( field ) ( 1: mri.dim (1), :, : ), mri.dim (1), mri.dim (2), mri.dim (3), [] );
        
        continue
    end
    
end
