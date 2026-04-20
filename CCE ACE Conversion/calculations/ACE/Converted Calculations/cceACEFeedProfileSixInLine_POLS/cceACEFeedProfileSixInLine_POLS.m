function [outputs,errorCode] = cceACEFeedProfileSixInLine_POLS(parameters, inputs)

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
        autofeedpoints = ["FeedBatch_Port1_tot", "FeedBatch_Port2_tot", ...
            "FeedBatch_Port3_tot", "FeedBatch_Port4_tot", "FeedBatch_Port5_tot", ...
            "FeedBatch_Port6_tot", "FeedBatch_Port7_tot", "FeedBatch_Port8_tot", ...
            "FeedBatch_Port9_tot"];

        profilepoints = ["ACE_Profile_1", "ACE_Profile_2", "ACE_Profile_3", ...
            "ACE_Profile_4", "ACE_Profile_5", "ACE_Profile_6", "ACE_Profile_7", ...
            "ACE_Profile_8", "ACE_Profile_9"];

        try
            totalfeeds = zeros(length(profilepoints), 1);

            %Generating the totalized values for use...
            for i = 1:length(autofeedpoints) %Assumed to be, at least, of the same length
                maxVal = max(inputs.(autofeedpoints(i)));
                if ~isempty(maxVal) && ~isnan(maxVal)
                    totalfeeds(i) = maxVal;
                end
            end


            %Calculate totals
            Total = sum(totalfeeds);

            %In the event of no feed, throw an exception
            if Total == 0
                throw(MException("FeedProfilePOLS_All:inputError", "No feed for the period"))
            end

            %Calculate the profile for each port
            feedprofile = totalfeeds ./ Total .* 100;

            for i = 1:length(profilepoints)
                outputs.(profilepoints(i)) = [feedprofile(i); feedprofile(i)];
            end

        catch ex

            logger.logError("FeedProfileSixInLine_POLS calc error: " + ex.message)

            %Output nan for all.
            for i = 1:length(profilepoints)
                outputs.(profilepoints(i)) = [NaN; NaN];
            end
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
        
    catch
        outputs.Timestamp = [];

        for i = 1:length(profilepoints)
            outputs.(profilepoints(i)) = [];
        end

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        logger.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
