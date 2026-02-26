function [ pH, vH ] = myom_trih ( p0, p1, p2 )

% Based on OpenMEEG functions:
% * operatorDipolePotDer by Alexandre Gramfort


% Gets the vectors defining the triangles.
v10    = p0 - p1;
v21    = p1 - p2;
v02    = p2 - p0;

v10n   = v10 ./ sqrt ( sum ( v10 .* v10, 2 ) );
v21n   = v21 ./ sqrt ( sum ( v21 .* v21, 2 ) );
v02n   = v02 ./ sqrt ( sum ( v02 .* v02, 2 ) );

% Calculates the intersection of each height and each side.
pH0    = sum ( v10 .* v21n, 2 ) .* v21n + p1;
pH1    = sum ( v21 .* v02n, 2 ) .* v02n + p2;
pH2    = sum ( v02 .* v10n, 2 ) .* v10n + p0;

% Gets the vector defining each height.
vH0    = p0 - pH0;
vH1    = p1 - pH1;
vH2    = p2 - pH2;

% Corrects the vectors by its norm-2.
vH0    = vH0 ./ sum ( vH0 .* vH0, 2 );
vH1    = vH1 ./ sum ( vH1 .* vH1, 2 );
vH2    = vH2 ./ sum ( vH2 .* vH2, 2 );

% Joins the three heights.
pH     = cat ( 3, pH0, pH1, pH2 );
vH     = cat ( 3, vH0, vH1, vH2 );
