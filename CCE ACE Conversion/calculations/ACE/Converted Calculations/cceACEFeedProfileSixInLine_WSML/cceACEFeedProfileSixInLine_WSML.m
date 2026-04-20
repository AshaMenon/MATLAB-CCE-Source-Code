function [outputs,errorCode] = cceACEFeedProfileSixInLine_WSML(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try
        
        second_date = ExeTime;
        second_date.Hour = 5;
        second_date.Minute = 0;
        second_date.Second = 0;

        first_date = second_date - caldays(1);
        first_date.Second = 1;

        outputs.Timestamp = [first_date; second_date];

        %Setting up the arrays to make this as generic as possible.
        autofeedpoints = ["Autofeed_Port1_tot", "Autofeed_Port2_tot", ...
            "Autofeed_Port3_tot", "Autofeed_Port4_tot", "Autofeed_Port5_tot", ...
            "Autofeed_Port6_tot", "Autofeed_Port7_tot"];

        manualfeedpoints = ["Manual_Port1_tot", "Manual_Port2_tot", ...
            "Manual_Port3_tot", "Manual_Port4_tot", "Manual_Port5_tot", ...
            "Manual_Port6_tot", "Manual_Port7_tot"];

        topupfeedpoints = ["TopUp_Port1_tot", "TopUp_Port2_tot", ...
            "TopUp_Port3_tot", "TopUp_Port4_tot", "TopUp_Port5_tot", ...
            "TopUp_Port6_tot", "TopUp_Port7_tot"];

        profilepoints = ["ACE_Profile_1", "ACE_Profile_2", "ACE_Profile_3", ...
            "ACE_Profile_4", "ACE_Profile_5", "ACE_Profile_6", "ACE_Profile_7"];

        try
            autofeeds = zeros(length(autofeedpoints),1);
            manualfeeds = zeros(length(manualfeedpoints),1);
            topupfeeds = zeros(length(topupfeedpoints),1);
            totalfeeds = zeros(length(profilepoints),1);
            feedprofile = zeros(length(profilepoints),1);
            total = 0;

            %Generating the totalized values for use...
            for i = 1:length(autofeedpoints) %Assumed to be, at least, of the same length
                totalfeeds(i) = totalfeeds(i) + ...
                    sum([max(inputs.(autofeedpoints(i))), ...
                    max(inputs.(manualfeedpoints(i))), ...
                    max(inputs.(topupfeedpoints(i)))], "omitmissing");
            end

            %Calculate total
            for i = 1:length(totalfeeds)
                total = total + totalfeeds(i);
            end

            %In the event of no feed, throw an exception
            if total == 0
                throw(MException("FeedProfileSixInLine:inputError", ...
                    "No feed for the period"))
            end

            %Calculate the profile for each port
            for i = 1:length(autofeeds)
                feedprofile(i) = totalfeeds(i) / total * 100;
            end

            %If we have got to this point, stop the standard output of the data and use the PISDK to write accurately timestamped data
            for i = 1:length(profilepoints)
                outputs.(profilepoints(i)) = [feedprofile(i); feedprofile(i)];
            end

        catch ex
            %Output NaN for all.
            for i = 1:length(profilepoints)
                outputs.(profilepoints(i)) = [nan; nan];
            end
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end

            if any(isinf(curOut))
                outputs.(outputNames(nOut)) = nan(size(curOut)); % Set to nan if output empty
            end
        end
        
    catch
        for i = 1:length(profilepoints)
            outputs.(profilepoints(i)) = [];
        end

        outputs.Timestamp = [];

        errorCode = cce.CalculationErrorState.CalcFailed;

        logger.logError(ex.message)
    end
end