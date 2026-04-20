function [outputs,errorCode] = cceACExDaysTotals(parameters, inputs)

    logger = CCELogger(parameters.LogName, parameters.CalculationID, ...
        parameters.CalculationName, parameters.LogLevel);

    newOutTime = strrep(parameters.OutputTime, "T", " ");
    newOutTime = extractBefore(newOutTime, ".");

    ExeTime = datetime(newOutTime);

    try
        logger.logTrace("Current execution time being used: " + string(ExeTime))
        errorCode = cce.CalculationErrorState.Good;

        utcSeconds = seconds(ExeTime - datetime('1970-01-01'));

        try
            % filePath = which('StreamMapperTotals.dll');
            filePath = "D://CCE Dependencies//CCE ACE Conversion//StreamMapperTotals//bin//StreamMapperTotals.dll";
            if isempty(which("StreamMapperTotals.xDaysTotals"))
                asm = NET.addAssembly(filePath); %#ok<NASGU>
            end
        catch ex
            logger.logTrace(ex.message)
            filePath = "D://CCE Dependencies//CCE ACE Conversion//StreamMapperTotals//bin//StreamMapperTotals.dll";
            logger.logTrace("Adding assembly at: " + string(filePath))
            if isempty(which("StreamMapperTotals.xDaysTotals"))
                asm = NET.addAssembly(filePath); %#ok<NASGU>
            end
        end
        

        % Calculation logic goes here
        %calcInstance = StreamMapperTotals.xDaysTotals;
        calcInstance = StreamMapperTotals.xDaysTotal.xDaysTotalClass;

        runCompleted = calcInstance.runCalc(utcSeconds, parameters.CalcPath);

        outputs.RunCompleted = runCompleted;
        outputs.Timestamp = ExeTime+hours(2);
    catch err

        if contains(err.message, "addAssembly", "IgnoreCase", true)
            outputs.RunCompleted = 1;
            outputs.Timestamp = ExeTime+hours(2);
        else
            logger.logError(['.NET exception: ' err.message])
            errorCode = cce.CalculationErrorState.CalcFailed;
            outputs.RunCompleted = nan;
            outputs.Timestamp = ExeTime+hours(2);
        end
        
    end
