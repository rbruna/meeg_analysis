function data = my_orderchans ( data, order )

% Two fields must be reordered: 'label' and 'trial'.

% Reorders the labels.
data.label = data.label ( order );

% Reorders all the trials.
data.trial = cellfun ( @(d) d ( order, : ), data.trial, 'UniformOutput', false' );