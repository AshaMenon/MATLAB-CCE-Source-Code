function [outputs, errorCode] = emptyOutputCalc(parameters, inputs)
    %nanCalc has two outputs, output1 is 1, and ouput2 is empty.
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try
        sensorRefTimestamp = datetime("now");

        outputs.Output1 = 1;
        outputs.Output2 = [];
        outputs.Timestamp = sensorRefTimestamp(end);

    catch err
        outputs.Output1 = [];
        outputs.Output2 = [];
        outputs.Timestamp = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        log.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
    errorCode = uint32(errorCode);
end
