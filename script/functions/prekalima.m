function beats = prekalima ( data )

scale = max ( data (:) );

% Extracts the metadata from the data.
samples = size ( data, 1 );

% Filters the EKG data and gets its envelope.
fir   = fir1 ( 1000, 10 / ( 1000 / 2 ), 'high' );
data  = my_filtfilt ( fir, 1, data, true );
data  = abs ( data );
fir   = fir1 ( 1000, 10 / ( 1000 / 2 ) );
data  = my_filtfilt ( fir, 1, data );

% Applies a z-score to the data.
data  = zscore ( data, 0, 1 );


% Extracts the beat area using a threshold.
beats = data > 2;

% Removes the incomplete areas.
for aindex = find ( beats ( 1, : ) > 0 )
    
    edge = find ( beats ( :, aindex ) == 0, 1, 'first' );
    beats ( 1: edge, aindex ) = 0;
end

for aindex = find ( beats ( end, : ) > 0 )
    
    edge = find ( beats ( :, aindex ) == 0, 1, 'last' );
    beats ( edge: end, aindex ) = 0;
end


% Rewrites the beat areas as a continous.
beats = beats (:);

% Extracts the edges of the triggers.
ups   = find ( diff ( beats ) > 0 );
downs = find ( diff ( beats ) < 0 );


% Extracts the R peaks as the maximum in each area.
peaks = zeros ( size ( ups ) );

for trig = 1: size ( ups, 1 )
    
    % Discards the trials shorter than 20 samples.
    if downs ( trig ) - ups ( trig ) < 20
        peaks ( trig ) = NaN;
        continue
    end
    
    % Stores the position of the maximum for the area.
    [ ~, peak ]    = max ( data ( ups ( trig ): downs ( trig ) ) );
    peaks ( trig ) = ups ( trig ) + peak;
end

% Removes the NaNs.
peaks = peaks ( ~isnan ( peaks ) );

% Gets the sample and trial of each peak.
peaks ( :, 2 ) = rem  ( peaks ( :, 1 ), samples );
peaks ( :, 3 ) = ceil ( peaks ( :, 1 ) / samples );


% % Analyzes the peaks too close.
% while any ( peaks ( find ( diff ( peaks ( :, 1 ) ) < 500 ) + 0, 3 ) == peaks ( find ( diff ( peaks ( :, 1 ) ) < 500 ) + 1, 3 ) )
%     
%     % Gets the peaks in conflict.
%     pindex = find ( peaks ( find ( diff ( peaks ( :, 1 ) ) < 500 ) + 0, 3 ) == peaks ( find ( diff ( peaks ( :, 1 ) ) < 500 ) + 1, 3 ), 1 );
%     
%     % Removes both peaks.
%     peaks ( pindex, : ) = [];
%     peaks ( pindex, : ) = [];
% end

% Creates the beats signal.
beats = zeros ( size ( data ) );
beats ( peaks ( :, 1 ) ) = 1.1 * scale;
