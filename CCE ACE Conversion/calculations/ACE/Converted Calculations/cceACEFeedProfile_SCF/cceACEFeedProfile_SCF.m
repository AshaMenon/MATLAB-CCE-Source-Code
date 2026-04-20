function [outputs,errorCode] = cceACEFeedProfile_SCF(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + datestr(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try

        TotaliseTime = 5;

        %Retrieving the right timestamp for reading
        nowtime = ExeTime;
        %start looking 10 min before totalising time
        starttime = nowtime;
        starttime.Hour = TotaliseTime - 1;
        starttime.Minute = 50;
        starttime.Second = 0;
        if nowtime.Hour < TotaliseTime %It's executed earlier than today's values - get yesterday's values
            starttime = starttime + days(-1);
        end
        endtime = starttime + minutes(70);

        %Retrieve the write-dates
        dates = CommonFunctions.GenerateTotPeriodDates(ExeTime, 86400, 18000);
        first_date = dates(1);
        second_date = dates(2);

        outputs.Timestamp = [first_date; second_date];

        %Setting up the arrays to make this as generic as possible.
        wallfeedpoints = ["WACS_Wall_Port10_tot", "WACS_Wall_Port12_tot", ...
            "WACS_Wall_Port14_tot", "WACS_Wall_Port5_tot", ...
            "WACS_Wall_Port7_tot", "WACS_Wall_Port8_tot"];

        deltafeedpoints = ["WACS_Delta_Port13_tot", "WACS_Delta_Port6_tot", ...
            "WACS_Delta_Port9_tot"];

        centrefeedpoints = "WACS_Centre_Port11_tot";

        wallprofilepoints = ["ACE_Profile_Wall_Port10", ...
            "ACE_Profile_Wall_Port12", "ACE_Profile_Wall_Port14", ...
            "ACE_Profile_Wall_Port5", "ACE_Profile_Wall_Port7", ...
            "ACE_Profile_Wall_Port8"];

        deltaprofilepoints = ["ACE_Profile_Delta_Port13", ...
            "ACE_Profile_Delta_Port6", "ACE_Profile_Delta_Port9"];

        totalprofilepoints = ["ACE_Profile_Total_Wall", ...
            "ACE_Profile_Total_Delta", "ACE_Profile_Total_Centre"];

        try
            wallfeeds = zeros(length(wallfeedpoints), 1);
            deltafeeds = zeros(length(deltafeedpoints), 1);
            centrefeeds = zeros(length(centrefeedpoints), 1);
            wallprofile = zeros(length(wallprofilepoints), 1);
            deltaprofile = zeros(length(deltaprofilepoints), 1);
            totalprofile = zeros(length(totalprofilepoints), 1);

            %Generating the totalized values for use...
            %Addition of all wall feeds
            for i = 1:length(wallfeedpoints)
                totalprofile(1) = totalprofile(1) + getMax(inputs, ...
                    wallfeedpoints(i), starttime, endtime);
            end

            %Addition of all delta feeds
            for i = 1:length(deltafeedpoints)
                totalprofile(2) = totalprofile(2) + getMax(inputs, ...
                    deltafeedpoints(i), starttime, endtime);
            end
            %Addition of centre feed
            totalprofile(3) = getMax(inputs, centrefeedpoints(1), ...
                starttime, endtime);

            %Calculation of wall profile
            for i = 1:length(wallprofilepoints)
                if totalprofile(1) > 0
                    wallprofile(i) = getMax(inputs, wallfeedpoints(i), ...
                        starttime, endtime) / totalprofile(1) * 100;
                else
                    wallprofile(i) = 0;
                end
            end

            %Calculation of delta profile
            for i = 1:length(deltaprofilepoints)
                if totalprofile(2) > 0
                    deltaprofile(i) = getMax(inputs, deltafeedpoints(i), ...
                        starttime, endtime) / totalprofile(2) * 100;
                else
                    deltaprofile(i) = 0;
                end
            end

            %Calculate total profile
            total = 0;
            for i = 1:length(totalprofile)
                total = total + totalprofile(i);
            end
            for i = 1:length(totalprofile)
                if total > 0
                    totalprofile(i) = totalprofile(i) / (total / 100);
                else
                    totalprofile(i) = 0;
                end
            end

            %In the event of no feed, throw an exception
            if total == 0
                throw(MException("FeedProfile_SCF:inputError", "No feed for the period"))
            end

            %If we have got to this point, stop the standard output of the data and use the PISDK to write accurately timestamped data
            for i = 1:length(wallprofilepoints)
                outputs.(wallprofilepoints(i)) = [wallprofile(i); wallprofile(i)];
            end
            for i = 1:length(deltaprofilepoints)
                outputs.(deltaprofilepoints(i)) = [deltaprofile(i); deltaprofile(i)];
            end
            for i = 1:length(totalprofilepoints)
                outputs.(totalprofilepoints(i)) = [totalprofile(i); totalprofile(i)];
            end

        catch ex
            %Output "Bad data" for all.
            %If we have got to this point, stop the standard output of the data and use the PISDK to write accurately timestamped data
            for i = 1:length(wallprofilepoints)
                outputs.(wallprofilepoints(i)) = [NaN; NaN];
            end
            for i = 1:length(deltaprofilepoints)
                outputs.(deltaprofilepoints(i)) = [NaN; NaN];
            end
            for i = 1:length(totalprofilepoints)
                outputs.(totalprofilepoints(i)) = [NaN; NaN];
            end

            logger.logError(ex.message)
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
        
    catch ex
        for i = 1:length(wallprofilepoints)
            outputs.(wallprofilepoints(i)) = [];
        end
        for i = 1:length(deltaprofilepoints)
            outputs.(deltaprofilepoints(i)) = [];
        end
        for i = 1:length(totalprofilepoints)
            outputs.(totalprofilepoints(i)) = [];
        end

        outputs.Timestamp = [];

        errorCode = cce.CalculationErrorState.CalcFailed;

        logger.logError(ex.message)
    end
end

function maxVal = getMax(inputs, tagName, startTime, endTime)

    timeIdx = isbetween(inputs.(tagName + "Timestamps"), startTime, endTime);
    maxVal = max(inputs.(tagName)(timeIdx));

    if isempty(maxVal)
        maxVal = 0;
    end

end