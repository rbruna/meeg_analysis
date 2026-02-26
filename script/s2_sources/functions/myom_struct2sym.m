function matrix = myom_struct2sym ( structure )
% Function to expand an OpenMEEG symmetric matrix object intro a full
% matrix.

% Generates a matrix of the given size.
matrix = zeros ( structure.size );

% Copies the upper diagonal from the structure data to the matrix.
matrix ( triu ( true ( structure.size ) ) ) = structure.data;

% Fills the lower diagonal transposing and removing the diagonal.
matrix = matrix + matrix' - diag ( diag ( matrix ) );
