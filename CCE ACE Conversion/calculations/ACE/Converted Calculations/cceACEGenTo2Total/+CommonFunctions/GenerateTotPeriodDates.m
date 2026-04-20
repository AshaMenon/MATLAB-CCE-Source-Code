function dates = GenerateTotPeriodDates(ExecTime, TotPeriod, TotOffset)

try
%     ExecTime_UTC = CLng(ParseTime(ParseTime(ExecTime.LocalDate.ToString).LocalDate.ToLocalTime.ToString).UTCSeconds) % to compensate for time zone adjustments when using universal time

    refDate = datetime('1970-01-01 00:00:00');
    ExecTimeSecs = seconds(ExecTime - refDate);
    % this gets the local date as seconds past 1 Jan 1970 00:00:00

    % compensate for time zone adjustments before finding datesg
    %get the remainder of the current time less the offset and the period
    ModTime = mod((ExecTimeSecs - TotOffset), TotPeriod);

    second_date = ExecTime - seconds(ModTime); % to compensate for time zone adjustments when using universal time

    first_date = second_date - seconds(TotPeriod) + seconds(1); % less period and add 1 second
    dates = [first_date, second_date];

catch 
    %It's stuffed - just give up already...
% %     Throw New Exception("Fundamental date calculation failed.")
end

end