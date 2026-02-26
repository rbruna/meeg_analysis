function headmodel = myom_build_sens ( headmodel, clean )

% Joins the head and sensor matrices, if both available.


% Checks the input.
if nargin < 2
    clean = false;
end


% Checks that the head model is valid.
headmodel  = myom_check_headmodel ( headmodel );


% Checks which matrices are available.
has_hm     = isfield ( headmodel, 'hm' );
has_ihm    = isfield ( headmodel, 'ihm' );
has_h2em   = isfield ( headmodel, 'h2em' );
has_h2mm   = isfield ( headmodel, 'h2mm' );
has_h2emhm = isfield ( headmodel, 'h2em_hm' );
has_h2mmhm = isfield ( headmodel, 'h2mm_hm' );


% If electrodes and inverse head matrices are pressent, calculates h2em/hm.
if ~has_h2emhm && has_ihm && has_h2em
    
    if myom_verbosity, fprintf ( 1, 'Calculating h2em * inv ( hm ).\n' ); end
    
    % Calculates h2em * inv ( hm ).
    headmodel.h2em_hm = headmodel.h2em * headmodel.ihm;
    has_h2emhm = true;
end

% If coils and inverse head matrices are pressent, calculates h2mm/hm.
if ~has_h2mmhm && has_ihm && has_h2mm
    
    if myom_verbosity, fprintf ( 1, 'Calculating h2em * inv ( hm ).\n' ); end
    
    % Calculates h2em * inv ( hm ).
    headmodel.h2mm_hm = headmodel.h2mm * headmodel.ihm;
    has_h2mmhm = true;
end


% If electrodes and head matrices are pressent, calculates h2em/hm.
if ~has_h2emhm && has_hm && has_h2em
    
    if myom_verbosity, fprintf ( 1, 'Calculating h2em * inv ( hm ).\n' ); end
    
    % Expands the symmetric matrix for the head model, if required.
    if isstruct ( headmodel.hm )
        hm = myom_struct2sym ( headmodel.hm );
    else
        hm = headmodel.hm;
    end
    
    % Calculates h2em * inv ( hm ).
    headmodel.h2em_hm = headmodel.h2em / hm;
    has_h2emhm = true;
end

% If coils and head matrices are pressent, calculates h2mm/hm.
if ~has_h2mmhm && has_hm && has_h2mm
    
    if myom_verbosity, fprintf ( 1, 'Calculating h2em * inv ( hm ).\n' ); end
    
    % Expands the symmetric matrix for the head model, if required.
    if isstruct ( headmodel.hm )
        hm = myom_struct2sym ( headmodel.hm );
    else
        hm = headmodel.hm;
    end
    
    % Calculates h2em * inv ( hm ).
    headmodel.h2mm_hm = headmodel.h2mm / hm;
    has_h2mmhm = true;
end


% Deletes the partial matrices, if requested.
if ( has_h2emhm || has_h2mmhm ) && clean
    if has_hm,   headmodel = rmfield ( headmodel, 'hm' );   end
    if has_ihm,  headmodel = rmfield ( headmodel, 'ihm' );  end
    if has_h2em, headmodel = rmfield ( headmodel, 'h2em' ); end
    if has_h2mm, headmodel = rmfield ( headmodel, 'h2mm' ); end
end
