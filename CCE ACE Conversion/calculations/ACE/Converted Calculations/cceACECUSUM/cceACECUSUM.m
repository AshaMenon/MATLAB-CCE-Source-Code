function [outputs,errorCode] = cceACECUSUM(parameters,inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    logger.logTrace("Current execution time being used: " + string(ExeTime))

    errorCode = cce.CalculationErrorState.Good;
    try

        %outputs.WriteTime = [];
        % Get properties
        try
            %outputs.WriteTime = CUSUM.CUSUM_Container.RetrieveWriteTimes(ExeTime);
            calcProperties = CUSUM.CUSUM_Container.RetrieveProperties(parameters);
        catch err
            logger.logError("Line: " + err.stack(1).line + ": " + err.message)
            %outputs.WriteTime = [];
        end
        % Populate the CUSUM values
        try
            popInfo = CUSUM.CUSUM_Container.PopulateCUSUMInformation(inputs,ExeTime,parameters);
            % aliases = fieldnames(inputs);
            % for i = 1:(length(aliases))/4
            %     name = "Alias"+i;
            %     outputs.(name+"_InputPoint") = popInfo.(name+"_InputPoint");
            %     outputs.(name+"_OutputPoint") = popInfo.(name+"_OutputPoint");
            %     outputs.(name+"_CurrentSample")= popInfo.(name+"_CurrentSample");
            %     outputs.(name+"_PreviousOutput") = popInfo.(name+"_PreviousOutput");
            %     outputs.(name+"_Average") = popInfo.(name+"_Average");
            % end
        catch err
            logger.logError("Line: " + err.stack(1).line + ": " + err.message)
            aliases = fieldnames(inputs);
            for i = 1:(length(aliases))/4
                name = "Alias"+i;
                popInfo.(name+"_InputPoint") = [];
                popInfo.(name+"_OutputPoint") = [];
                popInfo.(name+"_CurrentSample")= [];
                popInfo.(name+"_PreviousOutput") = [];
                popInfo.(name+"_Average") = [];
            end
        end

        % Update CUSUM values
        try
            updateVal = CUSUM.CUSUM_Container.UpdateCUSUMValue(popInfo,calcProperties,inputs);
            newAliases = fieldnames(inputs);
            for j = 1:(length(newAliases))/4
                updatedName = "Alias"+j;
                if ~isnan(double(updateVal.(updatedName+"_OutputPoint")))
                    outputs.(updatedName+"_OutputPoint") = double(updateVal.(updatedName+"_OutputPoint"));
                else
                    outputs.(updatedName+"_OutputPoint") = [];
                end
            end
        catch err
            logger.logError("Line: " + err.stack(1).line + ": " + err.message)
            newAliases = fieldnames(inputs);
            for j = 1:(length(newAliases))/4
                updatedName = "Alias"+j;
                outputs.(updatedName+"_OutputPoint") = [];
            end
        end

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            outputs.(outputNames(nOut)) = outputs.(outputNames(nOut))*2;
        end

        for k=3:6
            name = "Alias" + k;
            if inputs.(name)(end) < parameters.BaseTagAveMin || inputs.(name)(end) > parameters.BaseTagAveMax
                outputs.(name+"_OutputPoint") = inputs.(name)(end);
            end
        end

        outputs.Timestamp = ExeTime+hours(2);

        outputNames = string(fieldnames(outputs));

        for nOut = 1:length(outputNames)
            curOut = outputs.(outputNames(nOut));

            if isempty(curOut)
                outputs.(outputNames(nOut)) = nan; % Set to nan if output empty
            end
        end

    catch err
        outputs.Timestamp = [];
        outputs.WriteTime = [];
        for k = 1:(length(fieldnames(inputs)))/4
            nameOut = "Alias"+k;
            outputs.(nameOut+"_OutputPoint") = [];
        end
        logger.logError("Line: " + err.stack(1).line + ": " + err.message)

        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end

    end
