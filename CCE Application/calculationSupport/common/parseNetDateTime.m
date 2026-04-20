function [timestamp] = parseNetDateTime(timestamp)
    %PARSENETDATETIME parse a .NET DateTime object to a MATLAB datetime object
    
    kind = timestamp.Kind;
    if ~ismember(lower(string(kind)), "local")
        timestamp = System.TimeZoneInfo.ConvertTime(timestamp, System.TimeZoneInfo.Local);
    end
    timestamp = datetime(timestamp.Year, timestamp.Month, timestamp.Day, timestamp.Hour, timestamp.Minute, timestamp.Second, timestamp.Millisecond);
end