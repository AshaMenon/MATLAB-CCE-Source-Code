function dateFmt = smartdateformat(dateStart, dateEnd)
% Computes a smart date format based on a range.

% Copyright 2013 Anglo American Platinum
% $Revision: 1.1 $ $Date: 2012/07/24 08:37:28 $

if nargin<2 && length(dateStart)==2,
    dateEnd = dateStart(2);
    dateStart(2)=[];
end
dtDiff = dateEnd - dateStart;
numDays = floor(dtDiff);
if numDays > 365,
    % We must show the year
    dateFmt = 'yyyy-mm-dd';
% elseif numDays > 30,
%     % Must show the month
%     dateFmt = 'dd mmm';
elseif dtDiff > 23/24,
    % Must show at least the day and hour/minute
    dateFmt = 'dd mmm HH:MM';
elseif dtDiff < 3/24,
    % Must show seconds
    dateFmt = 'HH:MM:SS';
else
    dateFmt = 'HH:MM';
end