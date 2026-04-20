function ACEevent = GetACE2TotValue(ACETag, ExecTime,  ACE2TotPeriod, Tol)

ACEevent = [];
idxTimes = abs(days(ACETag.TimeStamp - ExecTime)) < 0.1 ;
Times = ACETag.TimeStamp(idxTimes);
Values = ACETag.Value(idxTimes);

if iscell(Values) 
    Values = zeros(numel(Times),1);
end

%get last good event
%get values in 2 periods
%find and validate last item

try
    %Get time, is calctime, go back one period then get values to get the total for the last period, otherwise the values for the next period could be returned
    GetDateEnd = ExecTime + seconds(-ACE2TotPeriod);
    GetDateStart = GetDateEnd + seconds(-ACE2TotPeriod);

    % Get events for 2 periods
    idx = isbetween(Times,GetDateEnd,GetDateStart);
    PIValue.Value = Values(idx);
    PIValue.TimeStamp = Times(idx);

    %loop through events and write values between dates

    if isempty(PIValue.Value)
        ACEevent.Value = nan(numel(Times),1); %no values
        ACEevent.TimeStamp = Times;
    end

    Events.TimeStamp = NaT;
    Events.Value = [];

    for ec = 1:length(PIValue.Value)

        if minute(PIValue.TimeStamp(ec)) == 0 && second(PIValue.TimeStamp(ec)) == 1
            if ~ismember(Events.TimeStamp, PIValue.TimeStamp(ec))
                Events.TimeStamp = [Events.TimeStamp; PIValue.TimeStamp(ec)];
                Events.Value = [Events.Value; PIValue.Value(ec)];
            end
        end
    end

    Events.TimeStamp(1) = [];

    %No good values
    if isempty(Events.Value)
        idx = (Times - ExecTime) < Tol;
    ACEevent.Value = Values(idx);
    ACEevent.TimeStamp = Times(idx);
    end

   
    [~, idx] = sort(Events.TimeStamp, 'descend');
    Events.TimeStamp = Events.TimeStamp(idx);
    Events.Value = Events.Value(idx);

    for eKey = 1:length(Events.TimeStamp) %newest first
        %If TimeStamp - ExecTime > CalcPeriod and < CalcPeriod*2 then got total value for period start

        TimeDiff = seconds(ExecTime - Events.TimeStamp(eKey)); %ExecTime_UTC - eKey
        %Time difference

        if TimeDiff >= ACE2TotPeriod && TimeDiff < ACE2TotPeriod * 2
            %Got a value in the range for the last period total, calc runs after the period end
            % so the first value of the last period Is further back than the 'calc time' - 1period ,
            % but Not as far back as the  'calc time' - 2period
            if ~isnan(Events.Value(eKey))
                ACEevent.TimeStamp = Events.TimeStamp(eKey);
                ACEevent.Value = Events.Value(eKey);

            else
                ACEevent.Value = [];
                ACEevent.TimeStamp = [];
            end

        end
    end % get newest first,

catch
    ACEevent.Value = [];
    ACEevent.TimeStamp = [];
end


end