function timestamp = mymff_time2unix ( datestring )

% 2016-03-10T19:17:35.643969-05:00
% Defines the regular expression for the date.
pattern   = '^(\d{4})-([0-1]\d)-([0-2]\d)T([0-2]\d):([0-5]\d):([0-5]\d).(\d{6})(-|+)([0-1]\d):([0-5]\d)$';

% Gets the parts of the date string.
dateparts = regexp ( datestring, pattern, 'tokens' );
dateparts = dateparts {1};
dateparts (8) = strcat ( dateparts (8), '1' );
dateparts = str2double ( dateparts );

% Gets the Matlab date representation for the date and time.
timezero  = datenum ( 1970, 1, 1, 0, 0, 0 ) * 24 * 60 * 60;
timebase  = datenum ( dateparts ( 1: 6 ) ) * 24 * 60 * 60;
timezone  = datenum ( 0, 0, 0, dateparts (9), dateparts (10), 0 ) * 24 * 60 * 60;
timestamp = timebase - dateparts (8) * timezone - timezero;

% Adds the microseconds.
timestamp = timestamp + 1e-6 * dateparts (7);