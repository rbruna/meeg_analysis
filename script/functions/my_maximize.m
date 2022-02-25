function my_maximize ( handles )

% Gets the handle objects.
handles = handle ( handles );

% Operates for each object.
for hindex = 1: numel ( handles )
    
    % Maximizes the figure, if possible.
    if isprop ( gcf, 'WindowState' )
        set ( gcf, 'WindowState', 'maximized' )
    
    else
        % Otherwise gets the Java frame.
        frame = get ( handles ( hindex ), 'JavaFrame' );
        
        % Maximizes the frame.
        frame.setMaximized ( true );
    end
end