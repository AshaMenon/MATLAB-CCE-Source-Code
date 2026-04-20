function [timestampOut] = parseMatlabDateTime(timestamp)
    %PARSENETDATETIME parse a MATLAB DateTime object to a .NET datetime object
    if size(timestamp,2) == 1
        timestampOut = NET.createArray('System.DateTime', numel(timestamp));
        for i = 1:numel(timestamp)
            iTime = timestamp(i);
            timestampOut(i) = System.DateTime(iTime.Year, iTime.Month, iTime.Day,...
                iTime.Hour, iTime.Minute, floor(iTime.Second), rem(iTime.Second, 1)*1000);
        end
    else
        timestampOut = NET.createArray('System.DateTime', size(timestamp));
        for i = 1:size(timestamp,1)
            iTime = timestamp(i,1);
            timestampOut(i,1) = System.DateTime(iTime.Year, iTime.Month, iTime.Day,...
                iTime.Hour, iTime.Minute, floor(iTime.Second), rem(iTime.Second, 1)*1000);
            iTime = timestamp(i,2);
            timestampOut(i,2) = System.DateTime(iTime.Year, iTime.Month, iTime.Day,...
                iTime.Hour, iTime.Minute, floor(iTime.Second), rem(iTime.Second, 1)*1000);
        end
    end
end