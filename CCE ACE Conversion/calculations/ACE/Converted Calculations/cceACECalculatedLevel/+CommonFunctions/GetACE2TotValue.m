function ACEevent = GetACE2TotValue(ACETag, ExecTime, ACE2TotPeriod, Tol)
ACEevent = [];
TimeJump = 1; % time added to first lookup time - in case there is a value at the lookup time
TotAdd = 1; % time added to first totaliser time
TimeRoundPlaces = 2;
MatchTime = nan;

%get last good event
%get values in 2 periods
%find and validate last item

try
    %Get time, is calctime, go back one period then get values to get the total for the last period, otherwise the values for the next period could be returned
    GetDateEnd = ExecTime + seconds(-ACE2TotPeriod);
    GetDateStart = GetDateEnd + seconds(-ACE2TotPeriod);

    % Get events for 2 periods
    idx = isbetween(ACETag.Times, GetDateStart, GetDateEnd);
    PIValues.Values = ACETag.Values(idx);
    PIValues.Times = ACETag.Times(idx);

    %loop through events and write values between dates

    if isempty(PIValues.Values)
        ACEevent.Values = []; %no values
        ACEevent.Times = [];
    end

    Events.Times = NaT;
    Events.Values = [];

    for ec = 1:length(PIValues.Values)
        %For Each _PIval As PIValue In _PIValues
        %only look at value with min =0 and seconds =1, get bad values too as result might be bad, if bad return nothing anyway
        %If _PIval.TimeStamp.LocalDate.Minute = 0 And _PIval.TimeStamp.LocalDate.Second = 0 Then
        %    If Not Events.ContainsKey(_PIval.TimeStamp.UTCSeconds) Then
        %        Events.Add(_PIval.TimeStamp.UTCSeconds, _PIval)
        %    End If

        %End If
        if minute(PIValues.Times(ec)) == 0 && second(PIValues.Times(ec)) == 1
            if ~ismember(Events.Times, PIValues.Times(ec))
                Events.Times = [Events.Times; PIValues.Times(ec)];
                Events.Values = [Events.Values; PIValues.Values(ec)];
            end
        end
    end

    Events.Times(1) = [];

    %No good values
    if isempty(Events.Values)
        ACEevent.Values = [];
        ACEevent.Times = [];
    end

    %calc time as UTC
    %Dim ExecTime_UTC As Long = CLng(ParseTime(ParseTime(ExecTime.LocalDate.ToString).LocalDate.ToLocalTime.ToString).UTCSeconds) ' for time zone adjustment

    [~, idx] = sort(Events.Times, 'descend');
    Events.Times = Events.Times(idx);
    Events.Values = Events.Values(idx);

    for eKey = 1:length(Events.Times) %newest first
        %If TimeStamp - ExecTime > CalcPeriod and < CalcPeriod*2 then got total value for period start

        TimeDiff = seconds(ExecTime - Events.Times(eKey)); %ExecTime_UTC - eKey
        %Time difference

        if TimeDiff >= ACE2TotPeriod && TimeDiff < ACE2TotPeriod * 2
            %Got a value in the range for the last period total, calc runs after the period end
            % so the first value of the last period Is further back than the 'calc time' - 1period ,
            % but Not as far back as the  'calc time' - 2period
            if ~isnan(Events.Values(eKey))
                ACEevent.Times = Events.Times(eKey);
                ACEevent.Values = Events.Values(eKey);

            else
                ACEevent.Values = [];
                ACEevent.Times = [];
            end

        end
    end % get newest first,

catch
    ACEevent.Values = [];
    ACEevent.Times = [];
end

end