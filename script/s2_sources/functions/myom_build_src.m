function headmodel = myom_build_src ( headmodel, clean )

% Joins the head and source matrices, if both available.


% Checks the input.
if nargin < 2
    clean = false;
end

% Checks that the head model is valid.
headmodel = myom_check_headmodel ( headmodel );


% Checks which matrices are available.
has_hm    = isfield ( headmodel, 'hm' );
has_ihm   = isfield ( headmodel, 'ihm' );
has_dsm   = isfield ( headmodel, 'dsm' );
has_hmdsm = isfield ( headmodel, 'hm_dsm' );


% If the source and inverse head matrices are present, calculates hm_dsm.
if ~has_hmdsm && has_ihm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Calculating inv ( hm ) * dsm.\n' ); end
    
    % Calculates inv ( hm ) * dsm.
    headmodel.hm_dsm = headmodel.ihm * headmodel.dsm;
    has_hmdsm = true;
end
    
% If the source and head matrices are present, calculates hm_dsm.
if ~has_hmdsm && has_hm && has_dsm
    
    if myom_verbosity, fprintf ( 1, 'Calculating inv ( hm ) * dsm.\n' ); end
    
    % Expands the symmetric matrix for the head model, if required.
    if isstruct ( headmodel.hm )
        hm = myom_struct2sym ( headmodel.hm );
    else
        hm = headmodel.hm;
    end
    
    % Calculates inv ( hm ) * dsm.
    headmodel.hm_dsm = hm \ headmodel.dsm;
    has_hmdsm = true;
end


% Deletes the partial matrices, if requested.
if has_hmdsm && clean
    if has_hm,  headmodel = rmfield ( headmodel, 'hm' );  end
    if has_ihm, headmodel = rmfield ( headmodel, 'ihm' ); end
    if has_dsm, headmodel = rmfield ( headmodel, 'dsm' ); end
end
