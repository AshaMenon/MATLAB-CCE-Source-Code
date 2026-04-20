function [outputs, errorCode] = nanCalc(parameters, inputs)
    %nanCalc has two outputs, two are always a NaN, and two are always
    %doubles. This is used for NaN replacement testing.
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try
        % sensorRefTimestamp = datetime("now");
        sensorRefTimestamp = datetime("now") - seconds(1);
        outputs.OutputSensorGood1 = 1;
        outputs.OutputSensorGood2 = 2;
        outputs.OutputSensorNaN2 = NaN;
        outputs.OutputSensorNaN1 = NaN;
        outputs.Timestamp = sensorRefTimestamp(end);

    catch err
        outputs.OutputSensorGood1 = [];
        outputs.OutputSensorGood2 = [];
        outputs.OutputSensorNaN2 = [];
        outputs.OutputSensorNaN1 = [];
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
