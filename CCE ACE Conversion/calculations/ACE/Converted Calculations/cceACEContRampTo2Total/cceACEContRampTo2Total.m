function [outputs, errorCode] = cceACEContRampTo2Total(parameters, inputs)
    %UNTITLED Summary of this function goes here
    %   Detailed explanation goes here

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime) + hours(2);

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    errorCode = cce.CalculationErrorState.Good;

    try

        %Run through list of alias in modual - input
        inputTags = string(fieldnames(inputs));
        inputTags(contains(inputTags, ["Timestamp", "Formula"])) = [];

        try
            AliasConfig = strsplit(inputTags(1), '_'); %delimit alias name
            LenConfig = length(AliasConfig);

            if LenConfig >= 3
                offset = double(AliasConfig(end)); %(last vlaue in delimit is time totaliser reset time/ offset)
                period = double(AliasConfig(end - 1)); %(last vlaue in delimit is time totaliser period)

                %set if config is in hours or seconds.

                if period <= 24
                    %period is in hours
                    period = period * 60 * 60;
                    offset = offset * 60 * 60;
                end


                %check that ramping tag is for 24 hours (second last value), if not skip
                %Retrieve the write-dates

                second_date = ExeTime;
                second_date.Hour = 0;
                second_date.Minute = 0;
                second_date.Second = 0;
                second_date = second_date+seconds(offset);
                first_date = second_date-caldays(1)+seconds(1);

                outputs.Timestamp = [first_date; second_date];

                %get data
                try
                    %SetPointTimes()
                    timeIdx =  isbetween(inputs.(inputTags(1)+"Timestamps"), first_date,second_date);
                    inData = inputs.(inputTags(1))(timeIdx);
                    compdev = parameters.CompDev;
                    Min = min(inData);
                    Max = max(inData);
                    startval = inData(1);
                    endval = inData(end);
                    zero = parameters.Zero;
                    %isreset = false;

                    if isempty(startval) || isnan(startval)
                        startval = 0;
                    end

                    if isempty(endval) || isnan(endval)
                        endval = 0;
                    end

                    if isempty(Min) || isnan(Min)
                        Min = 0;
                    end

                    if isempty(Max) || isnan(Max)
                        Max = 0;
                    end

                    %Checking for reset.
                    if Min < (zero + compdev) && Min > (zero - compdev) && Max ~= endval
                        Tot = endval - Min + Max - startval;
                    else
                        Tot = abs(endval - startval);
                    end

                    if isempty(Tot)
                        Tot = nan;
                    end
                    %Checking for negatives.
                    if Tot < 0
                        Tot = 0;
                    end

                catch err
                    msg = [err.stack(1).name, ' Line ',...
                        num2str(err.stack(1).line), '. ', err.message];

                    logger.logError(msg);
                    %throw(MException("ContRampTo2Total:inputError", "Data calculation failure - " + ex.message))
                end

                %get conversion and calc
                try
                    if isfield(parameters, "Formula")
                        convFac = parameters.Formula;

                        if ~isnan(str2double(convFac))
                            convFac = str2double(convFac);
                        end

                        if ischar(convFac) || isstring(convFac)
                            %get formula
                            Tot = CommonFunctions.EvalFormulaString(Tot, inputs, convFac, ExeTime);
                        else
                            Tot = Tot * convFac;
                        end
                    end

                    if isempty(Tot)
                        Tot = NaN;
                    end
     
                    outputs.("Out_" + inputTags(1)) = [Tot; Tot];

                catch ex
                    outputs.("Out_" + inputTags(1)) = [nan; nan];
                    outputs.Timestamp = [first_date; second_date];
                    logger.logError( "conversion get fail: " + ex.stack(1).name + ...
                        " " + ex.stack(1).line + " " + ex.message)
                end

            end

        catch ex
            outputs.("Out_" + inputTags(1)) = [nan; nan];
            outputs.Timestamp = [first_date; second_date];
            logger.logError( "Calculation error: " + ex.stack(end).name + ...
                " " + ex.stack(end).line + " " + ex.message)
        end

        if isempty(outputs.("Out_" + inputTags(1)))
            outputs.("Out_" + inputTags(1)) = [nan;nan]; % Set to nan if output empty
        end


    catch err
        outputs.Timestamp = [];
        inputTags = string(fieldnames(inputs));
        inputTags(contains(inputTags,["Timestamp", "Formula"])) = [];

        outputs.("Out_" + inputTags(1)) = [];
        outputs.Timestamp = [];

        errorCode = cce.CalculationErrorState.CalcFailed;

        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];

        logger.logError(msg);
    end
end