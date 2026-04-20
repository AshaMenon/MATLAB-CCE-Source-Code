function Val = GetEndOfDay(CurrentTag, Period, Offset, TagType, ExecTimeD, MatchTol)

Val = [];

try

    %Retrieve the write-dates
    dates = CommonFunctions.GenerateTotPeriodDates(ExecTimeD, Period, Offset);

    first_date = dates(1);
    second_date = dates(2);

    %Get PIACEPoint from PIAlias
    % CurrentTag As New PIACEPoint
    %CurrentTag.SetTag(PI_Alias.DataSource.Server.Name.ToString, PI_Alias.DataSource.Name, TagAliasUsedType.TagAliasAsInput)

    switch TagType

        case "2Tot" % 2 value totaliser 06:00:01 to 06:00:00 for 24 hour period
            Val = CommonFunctions.GetACE2TotValue(CurrentTag, ExecTimeD, Period, MatchTol);
            Val = Val.Values;
        case "ETot" %Value at end of period
            Val = CommonFunctions.GetValueAtTime(CurrentTag, second_date, 600, 7200);
            Val = Val.Value;
            %Val = CurrentTag.Max(second_date.AddMinutes(-30), second_date.AddMinutes(+10)) ' does not work if no values, returns the previous value
        case "STot" %Value at start of period
            Val = CommonFunctions.GetValueAtTime(CurrentTag, first_date, 600, 7200);
            Val = Val.Value;
            %Val = CurrentTag.Max(first_date.AddSeconds(-1).AddMinutes(-30), first_date.AddSeconds(-1).AddMinutes(+10))
        case "Devnt" %Sum of events in period
            Val = CommonFunctions.GetTotalizedPeriod(CurrentTag, first_date, second_date);
        case "Dmeas" %Time weighted sum of data in period
            Val = getSummary(CurrentTag, first_date, second_date, "Total", 0.8);
        case "MeasE" %Prevoius good event of plant data from the end date of the period
            Val = CommonFunctions.GetLastGood(CurrentTag, second_date);
            Val = Val.Value;
        case "Ramp" %Ramping tag reset at the end of the period
            Val = getSummary(CurrentTag, second_date +minutes(-30), second_date + minutes(10), "Max");
        case "EInt" %Value Interpolated at the period end time
            Val = CommonFunctions.IterpolatedVal(CurrentTag, second_date);
            Val = Val.Value;
        case "SInt" %Value Interpolated at the period start time
            Val = CommonFunctions.IterpolatedVal(CurrentTag, first_date);
            Val = Val.Value;
        case "EAt" %Value at the end time
            Val = CommonFunctions.GetValueAtTime(CurrentTag, second_date, 0.25);
            Val = Val.Value;
        case "SAt" %Value at the start time
            Val = CommonFunctions.GetValueAtTime(CurrentTag, first_date, 0.25);
            Val = Val.Value;
        case "TStdDev" %time weighted Standard Deviation
            Val = getSummary(CurrentTag, first_date, second_date, "Std");
        case "TAve" %time weighted Average
            Val = getSummary(CurrentTag, first_date, second_date, "Avg");
        case "TSum"
            Val = getSummary(CurrentTag, first_date, second_date, "Total", 30);
        case "eStdDev" %Standard deviation were all inputs are events
            % input event collection is restricted to 1 day or less in this case
            RetVal = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, 0, "event");
            RetVal = std(RetVal.Values);
            if isnan(RetVal)
                Val = "No Sample";
            else
                Val = RetVal;
            end

        case "eAve" %Standard deviation were all inputs are events
            % input event collection is restricted to 1 day or less in this case
            Val = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, 0, "event");
            Val = mean(Val.Values);
            %case "2TotStdev" 'Standard deviation were all inputs are 2 point Totalisers
            % function limits this to maximum one day and also to a window = to the period, so running the function below will always return 1 value
            %    Val = Stdev(GetInputEvents(CurrentTag, first_date, second_date, Period, "2Tot").Values.ToArray)
        case "eTot" %Event total for the period
            Val = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, 0, "event");
            Val = sum(Val.Values);
        case "EvTot" %Event total for the period
            Val = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, 0, "event");
            Val = sum(Val.Values);
        case "Max"
            Val = getSummary(CurrentTag, first_date, second_date, "Max");
        case "Min"
            Val = getSummary(CurrentTag, first_date, second_date, "Min");
        case "2Shift2TotSum"
            Val = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, (Period / 2), "2tot");
            Val = sum(Val.Values);
        case "3Shift2TotSum"
            Val = CommonFunctions.GetInputEvents(CurrentTag, first_date, second_date, (Period / 3), "2tot");
            Val = sum(Val.Values);
        otherwise
            Val = [];
    end


catch 

end
end

function sumVal = getSummary(tag, startTime, endTime, summaryType, pctGood)

    arguments
        tag
        startTime
        endTime
        summaryType
        pctGood = 0;
    end

    timeIdx = isbetween(tag.Times, startTime, endTime);

    switch summaryType
        case "Max"
            sumVal = max(tag.Values(timeIdx));
        case "Avg"
            sumVal = mean(tag.Values(timeIdx));
        case "Min"
            sumVal = min(tag.Values(timeIdx));
        case "Std"
            sumVal = std(tag.Values(timeIdx));
        case "Total"
            values = tag.Values(timeIdx);
            valGoodPer = mean(~isnan(values))*100;
            if valGoodPer > pctGood
                sumVal = sum(values);
            else
                sumVal = 0;
            end
    end

    if isempty(maxVal)
        sumVal = 0;
    end

end