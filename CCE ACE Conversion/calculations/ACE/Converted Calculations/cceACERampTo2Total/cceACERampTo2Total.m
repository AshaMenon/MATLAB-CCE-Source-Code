function [outputs,errorCode] = cceACERampTo2Total(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    errorCode = cce.CalculationErrorState.Good;

    try
        %Run through list of alias in module - input tags

        inputTags = string(fieldnames(inputs));
        inputTags(contains(inputTags, ["Timestamp", "Formula"])) = [];

        Tot = nan;

        try
            AliasConfig = strsplit(inputTags(1), "_"); %delimit alias name
            LenConfig = length(AliasConfig);

            if LenConfig >= 3 %got required number of variables

                %Get PIACEPoint from PIAlias
                CurrentTag.Times = inputs.(inputTags(1)+"Timestamps");
                CurrentTag.Values = inputs.(inputTags(1));

                Period = double(AliasConfig(LenConfig - 1));
                Offset = double(AliasConfig(LenConfig));

                %set if config is in hours or seconds.
                if Period <= 24
                    %period is in hours
                    Period = Period * 60 * 60;
                    Offset = Offset * 60 * 60;
                end

                % dates = CommonFunctions.GenerateTotPeriodDates(ExeTime, Period, Offset);
                ExeTime.Hour = 5;
                ExeTime.Minute = 0;
                ExeTime.Second = 0;

                second_date = ExeTime;
                first_date = ExeTime;
                first_date.Second = 1;
                first_date = first_date - caldays(1);

                %get data
                try
                    %SetPointTimes()
                    idx = isbetween(inputs.(inputTags(1) + "Timestamps"), second_date - minutes(30), second_date + minutes(10));
                    Tot = max(inputs.(inputTags(1))(idx));

                catch ex
                    outputs.("Out_" + inputTags(1)) = [nan; nan];
                    throw(MException("RampTo2Total:inputError", "Data get fail " + ex.message))
                end

                try
                    if iscell(parameters.Formula)
                        convFac = parameters.Formula{1};
                    else
                        convFac = parameters.Formula(1);
                    end

                    if ~isnan(str2double(convFac))
                        convFac = str2double(convFac);
                    end

                    if ischar(convFac)
                        %get formula
                        Tot = CommonFunctions.EvalFormulaString(Tot, inputs, convFac, ExeTime);

                    else
                        Tot = Tot * convFac;
                    end

                catch ex
                    outputs.("Out_" + inputTags(1)) = [nan; nan];
                    throw(MException("RampTo2Total:inputError", "conversion get fail " + ex.message))
                end
                %get output tag name
                % OutTagName As String = CurModule.PIModules(OutPutTagModual_Name).PIAliases(inputTags(1).Name).DataSource.Name

                outputs.("Out_" + inputTags(1)) = [Tot; Tot];

            end
        catch

        end

        %testing if used to skip items so that specific aliases can be checked
        %End If

        outputs.Timestamp = [first_date; second_date];

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end
    catch
        outputs.Timestamp = [];
        inputTags = string(fieldnames(inputs));
        inputTags(contains(inputTags,["Timestamp", "Formula"])) = [];

        outputs.(inputTags(1)) = [];

        errorCode = cce.CalculationErrorState.CalcFailed;

        logger.logError(ex.message)
    end
