function data = kalima ( data, EKG )

% Extracts the metadata from the data.
[ samples, channels, ~ ] = size ( data );

% Filters the EKG data and gets its envelope.
fir   = fir1 ( 1000, 10 / ( 1000 / 2 ), 'high' );
EKG   = my_filtfilt ( fir, 1, EKG, true );
EKG   = abs ( EKG );
fir   = fir1 ( 1000, 10 / ( 1000 / 2 ) );
EKG   = my_filtfilt ( fir, 1, EKG );


% Applies a z-score to the EKG data.
EKG   = zscore ( EKG, 0, 1 );

% Extracts the beat area using a threshold.
beats = EKG > 2;

% Removes the incomplete areas.
for aindex = find ( beats ( 1, : ) > 0 )
    
    edge = find ( beats ( :, aindex ) == 0, 1, 'first' );
    beats ( 1: edge, aindex ) = 0;
end

for aindex = find ( beats ( end, : ) > 0 )
    
    edge = find ( beats ( :, aindex ) == 0, 1, 'last' );
    beats ( edge: end, aindex ) = 0;
end


% Rewrites the EKG beat areas as a continous.
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
    [ ~, peak ]    = max ( EKG ( ups ( trig ): downs ( trig ) ) );
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

% % Gets the minumum distance two R peaks of the same trial.
% qrsl = min ( diff ( peaks ( peaks ( :, 2 ) > 1000 & peaks ( :, 3 ) < samples - 1000, 1 ) ) );

% Gets the most usual distance between two R peaks in the same trial.
qrsl = mode ( diff ( peaks ( peaks ( :, 2 ) > 1000 & peaks ( :, 3 ) < samples - 1000, 1 ) ) );

% Removes the R peaks too close to the edges.
peaks ( peaks ( :, 2 ) < round ( qrsl / 3 ) + 1, : ) = [];
peaks ( peaks ( :, 2 ) > samples - round ( 2 * qrsl / 3 ), : ) = [];


% Reserves memory for the QRS waveforms.
qrss  = zeros ( qrsl, channels, size ( peaks, 1 ) );

% Extracts the QRS waveforms window from the EKG components.
for pindex = 1: size ( peaks, 1 )
    
    % Extracts the QRS complex edges.
    qrsb = peaks ( pindex, 2 ) - round ( qrsl / 3 ) + 1;
    qrse = peaks ( pindex, 2 ) + round ( 2 * qrsl / 3 );
    qrst = peaks ( pindex, 3 );
    
    qrss ( :, :, pindex ) = data ( qrsb: qrse, :, qrst );
end

% Calculates the average QRS waveform.
qrs   = mean ( qrss, 3 );

% Removes the jumps at the bigining and the end of the QSR waveform.
for c = 1: size ( qrs, 2 )
    qrs ( :, c ) = qrs ( :, c ) - linspace ( qrs ( 1, c ), qrs ( end, c ), size ( qrs, 1 ) )';
end


% Constructs a signal of QRS complexes: The EKG projection.
proj  = zeros ( size ( data ) );

for pindex = 1: size ( peaks, 1 )
    
    % Extracts the QRS complex edges.
    qrsb = peaks ( pindex, 2 ) - round ( qrsl / 3 ) + 1;
    qrse = peaks ( pindex, 2 ) + round ( 2 * qrsl / 3 );
    qrst = peaks ( pindex, 3 );
    
    % Goes through each input signal.
    for signal = 1: channels
        
        % Scales the QRS complex to maximize the projection.
        scale  = regress ( detrend ( qrss ( :, signal, pindex ), 0 ), detrend ( qrs ( :, signal ), 0 ) );
        
        proj   ( qrsb: qrse, signal, qrst ) = qrs ( :, signal ) * scale;
    end
end

% for c = 1: size ( data, 2 )
%     figure
%     hold on
%     plot ( reshape ( data ( 2001: 6000, c, : ), [], 1 ) )
%     plot ( reshape ( proj ( 2001: 6000, c, : ), [], 1 ), 'r' )
%     plot ( reshape ( data ( 2001: 6000, c, : ) - proj ( 2001: 6000, c, : ), [], 1 ), 'k' )
%     
%     figure
%     hold on
%     plot ( mean ( abs ( fft ( data ( 2001: 6000, c, : ) ) ), 3 ) )
%     plot ( mean ( abs ( fft ( data ( 2001: 6000, c, : ) - proj ( 2001: 6000, c, : ) ) ), 3 ), 'r' )
%     xlim ( [ 0 45 * 8 ] )
% end

% Removes the EKG projection from the data.
data = data - proj;
