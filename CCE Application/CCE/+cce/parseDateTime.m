function [systemDateTime] = parseDateTime(mldatetime)
    %PARSEDATETIME converts MATLAB datetime datatype to an equivalent time System.Datetime
    %data type.
    % For MATLAB times that are NaT, set the .NET System.Datetime to UTC Zero:
    % 01-January-1970 00:00
    
    if ~ismissing(mldatetime)
        mldatetime.TimeZone = 'Local';
        mldatetime.TimeZone = 'UTC';
        [Y, M, D, H, Mn, S] = datevec(mldatetime);
    else
        [Y, M, D, H, Mn, S] = deal(1970, 1, 1, 0, 0, 0);
    end
    
    systemDateTime = System.DateTime(Y, M, D, H, Mn, S, System.DateTimeKind.Utc);
end

