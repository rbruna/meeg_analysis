function varargout = my_deal ( input )

if numel ( input ) ~= nargout
    error ( 'Incorrect input size.' );
end

varargout = num2cell ( input );