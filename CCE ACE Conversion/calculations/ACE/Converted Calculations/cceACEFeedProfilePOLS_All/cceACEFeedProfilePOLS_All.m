function [outputs,errorCode] = cceACEFeedProfilePOLS_All(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))
    errorCode = cce.CalculationErrorState.Good;

    try

        first_date = ExeTime - caldays(1);
        first_date.Hour = 6;
        first_date.Minute = 0;
        first_date.Second = 1;

        second_date = first_date + caldays(1);
        second_date.Second = 0;

        outputs.Timestamp = [first_date; second_date];

        %Setting up the arrays to make this as generic as possible.
        EastFeedpoints = ["FeedBatch_Port1_tot", "FeedBatch_Port2_tot", ...
            "FeedBatch_Port3_tot", "FeedBatch_Port4_tot", "FeedBatch_Port5_tot", ...
            "FeedBatch_Port6_tot", "FeedBatch_Port7_tot", "FeedBatch_Port8_tot", ...
            "FeedBatch_Port9_tot"];

        WestFeedpoints = ["FeedBatch_Port1_tot_2", "FeedBatch_Port2_tot_2", ...
            "FeedBatch_Port3_tot_2", "FeedBatch_Port4_tot_2", "FeedBatch_Port5_tot_2", ...
            "FeedBatch_Port6_tot_2", "FeedBatch_Port7_tot_2", "FeedBatch_Port8_tot_2", ...
            "FeedBatch_Port9_tot_2"];

        EastProfilepoints = ["ACE_Profile_E1", "ACE_Profile_E2", "ACE_Profile_E3", ...
            "ACE_Profile_E4", "ACE_Profile_E5", "ACE_Profile_E6", "ACE_Profile_E7", ...
            "ACE_Profile_E8", "ACE_Profile_E9"];

        WestProfilepoints = ["ACE_Profile_W1", "ACE_Profile_W2", "ACE_Profile_W3", ...
            "ACE_Profile_W4", "ACE_Profile_W5", "ACE_Profile_W6", "ACE_Profile_W7", ...
            "ACE_Profile_W8", "ACE_Profile_W9"];

        try
            EastTotalfeeds = zeros(length(EastProfilepoints), 1);
            WestTotalfeeds = zeros(length(WestProfilepoints), 1);

            %Generating the totalized values for use...
            for i = 1:length(EastFeedpoints) %Assumed to be, at least, of the same length
                maxVal = max(inputs.(EastFeedpoints(i)));
                if ~isempty(maxVal) && ~isnan(maxVal)
                    EastTotalfeeds(i) = maxVal;
                end
            end

            for i = 1:length(WestFeedpoints) %Assumed to be, at least, of the same length
                maxVal = max(inputs.(WestFeedpoints(i)));
                if ~isempty(maxVal) && ~isnan(maxVal)
                    WestTotalfeeds(i) = maxVal;
                end
            end

            %Calculate totals
            EastTotal = sum(EastTotalfeeds);
            WestTotal = sum(WestTotalfeeds);

            Total = EastTotal + WestTotal;

            %In the event of no feed, throw an exception
            if Total == 0
                throw(MException("FeedProfilePOLS_All:inputError", "No feed for the period"))
            end

            %Calculate the profile for each port
            EastFeedprofile = EastTotalfeeds ./ Total .* 100;

            WestFeedprofile = WestTotalfeeds ./ Total .* 100;

            %East and west profile of furnace
            EastProfile = EastTotal / Total * 100;
            WestProfile = WestTotal / Total * 100;

            %ACE_Profile_WTotal()

            outputs.ACE_Profile_ETotal = [EastProfile; EastProfile];
            outputs.ACE_Profile_WTotal = [WestProfile; WestProfile];

            logger.logTrace(string(EastProfile))
            % logger.logTrace(length(WestProfile))

            for i = 1:length(EastProfilepoints)
                outputs.(EastProfilepoints(i)) = [EastFeedprofile(i); EastFeedprofile(i)];
            end

            for i = 1:length(WestProfilepoints)
                outputs.(WestProfilepoints(i)) = [WestFeedprofile(i); WestFeedprofile(i)];
            end

            outputNames = string(fieldnames(outputs));

            for nOut = 1:length(outputNames)
                curOut = outputs.(outputNames(nOut));

                if isempty(curOut)
                    outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
                end
            end

        catch ex

            logger.logError("FeedProfilePOLS_All calc error: " + ex.message)

            outputs.ACE_Profile_ETotal = [NaN; NaN];
            outputs.ACE_Profile_WTotal = [NaN; NaN];

            %Output nan for all.
            for i = 1:length(EastProfilepoints)
                outputs.(EastProfilepoints(i)) = [NaN; NaN];
            end

            for i = 1:length(WestProfilepoints)
                outputs.(WestProfilepoints(i)) = [NaN; NaN];
            end
        end
    catch err
        outputs.Timestamp = [];
        outputs.ACE_Profile_ETotal = [];
        outputs.ACE_Profile_WTotal = [];

        for i = 1:length(EastProfilepoints)
            outputs.(EastProfilepoints(i)) = [];
        end

        for i = 1:length(WestProfilepoints)
            outputs.(WestProfilepoints(i)) = [];
        end

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
end
