function rank = my_rank ( s )
% Matlab's rank.m and SPM's spm_pca_order.m (Minka's approximation) seem to
% estimate the rank of Maxfiltered or AFRICAed data poorly... Please feel
% free to augment this function with a better estimation approach.

minRank = 40;

eigDiff = diff ( log ( s ) );

rankVec = eigDiff < 10 * median ( eigDiff );
rankVec ( 1: minRank ) = false;

rank = find ( rankVec, 1, 'first' );

if isempty ( rank )
    rank = numel ( s );
end

rank = rank;