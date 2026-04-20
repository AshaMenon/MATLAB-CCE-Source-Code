function [outputs,errorCode] = cceACEDailyChargePrepTotals(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);
    ExeTime = ExeTime + hours(2);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try

        % Gets value for Wet Feed total for a specific period
        FD2_WFeed = GetACE2TotValue(inputs.ACE_WetFeed_Tot,inputs.ACE_WetFeed_TotTimestamps, ExeTime, 86400, 0.5);

        % Gets value for Wet feed Total 2 for a specific period
        FD3_WFeed = GetACE2TotValue(inputs.ACE_WetFeed_Tot_2,inputs.ACE_WetFeed_Tot_2Timestamps, ExeTime, 86400, 0.5);

        % Gets value for Wet Feed total 3 for a specific period
        FD4_WFeed = GetACE2TotValue(inputs.ACE_WetFeed_Tot_3,inputs.ACE_WetFeed_Tot_3Timestamps, ExeTime, 86400, 0.5);

        % outputs the sum of the wet feed values obtained
        outputs.T_WFeed = FD2_WFeed.Value + FD3_WFeed.Value + FD4_WFeed.Value;

        SM_WFeed = inputs.T_Wet_Feed_Tot(1);
        massPull = GetLastGood(inputs.M_Mass_Pull, inputs.M_Mass_PullTimestamps, ExeTime);
        SM_MassPull = massPull.Value / 100;

        PMA_Feed_H2O = GetLastGood(inputs.PMA_Feed_H2O, inputs.PMA_Feed_H2OTimestamps,ExeTime);
        PMA_Feed_H2O_2 = GetLastGood(inputs.PMA_Feed_H2O_2, inputs.PMA_Feed_H2O_2Timestamps,ExeTime);
        PMA_Feed_H2O_3 = GetLastGood(inputs.PMA_Feed_H2O_3, inputs.PMA_Feed_H2O_3Timestamps,ExeTime);
        PMA_Feed_H2O_4 = GetLastGood(inputs.PMA_Feed_H2O_4, inputs.PMA_Feed_H2O_4Timestamps,ExeTime);

        FD2_D = (1 - PMA_Feed_H2O.Value ./ 100) .* FD2_WFeed.Value;
        FD3_D = (1 -  PMA_Feed_H2O_2.Value ./ 100) .* FD3_WFeed.Value;
        FD4_D = (1 - PMA_Feed_H2O_3.Value ./ 100) .* FD4_WFeed.Value;
        Tot_D  = FD2_D + FD3_D + FD4_D;
        SM_D  = (1 -  PMA_Feed_H2O_4.Value ./ 100) .* SM_WFeed;
        SM_T  = SM_D * (1 - SM_MassPull);

        ExeTime.Hour = 5;
        ExeTime.Minute = 0;
        ExeTime.Second = 0;
        outputs.Timestamp = ExeTime;

        outputs.FD2_D = FD2_D;
        outputs.FD3_D = FD3_D;
        outputs.FD4_D = FD4_D;
        outputs.Tot_D = Tot_D;
        outputs.SM_D = SM_D;
        outputs.SM_T = SM_T;

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
    catch err
        outputs.T_WFeed = [];
        outputs.FD2_D = [];
        outputs.FD3_D = [];
        outputs.FD4_D = [];
        outputs.Tot_D = [];
        outputs.SM_T = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end

    end

end

function point = GetLastGood(Tag,TagTimes, CurTime)

    try

        idx = find(TagTimes < CurTime, 1, "last");

        if ~isempty(idx)

            point.Value = Tag(idx);
            point.Time = TagTimes(idx);

        else
            point.Value = [];
            point.Time = [];
        end

        if isnan(point.Value) || isempty(point.Value)
            point.Value = 0;
        end

    catch

        point.Value = 0;
        point.Time = [];

    end
end

function ACEevent = GetACE2TotValue(ACETag, ACETagTimes, ExecTime, ACE2TotPeriod, Tol)
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
        idx = isbetween(ACETagTimes, GetDateStart, GetDateEnd);
        PIValues.Values = ACETag(idx);
        PIValues.Times = ACETagTimes(idx);

        %loop through events and write values between dates

        if isempty(PIValues.Values)
            ACEevent.Value = 0; %no values
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
            ACEevent.Value = 0;
            ACEevent.Times = 0;
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
                    ACEevent.Value = Events.Values(eKey);

                else
                    ACEevent.Value = 0;
                    ACEevent.Times = [];
                end

            end
        end % get newest first,

        if isnan(ACEevent.Value) || isempty(ACEevent.Value)
            ACEevent.Value = 0;
        end

    catch
        ACEevent.Value = 0;
        ACEevent.Times = [];
    end

end