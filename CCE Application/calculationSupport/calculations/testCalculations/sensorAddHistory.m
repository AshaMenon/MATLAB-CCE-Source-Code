function [outputs, errorCode] = sensorAddHistory(parameters,inputs)
    %SENSORADDHISTORY Synthetic calculation created to test calculation historical outputs
    %   Reads last two values from the sensor input and writes out two values at
    %   the same time stamps, offset by the Offset parameter.
    %
    %   Set up this calculation with a sample rate of N, and inputs samples
    %   at least twice as fast as N.
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try   
        % Assign Parameters
        offset = parameters.Offset;
        
        % Assign Inputs
        sensorRef = inputs.SensorReference;
        sensorRefTimestamp = inputs.SensorReferenceTimestamps;

        % Input checking
        if numel(sensorRef) < 2
            errorCode = cce.CalculationErrorState.InputConfigInvalid;
            error("ons:sensorAddHistory:InvalidInputs", "Input specification does not include two samples.");
        end
        
        outputs.OutputSensor = sensorRef(end-1:end) + offset;
        outputs.Timestamp = sensorRefTimestamp(end-1:end);
        log.logTrace('Output: %s / %.2f', string(outputs.Timestamp(1), "yyyy-MM-dd hh:mm:ss"), outputs.OutputSensor(1));
        log.logTrace('Output: %s / %.2f', string(outputs.Timestamp(2), "yyyy-MM-dd hh:mm:ss"), outputs.OutputSensor(2));

    catch err
        outputs.OutputSensor = [];
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
