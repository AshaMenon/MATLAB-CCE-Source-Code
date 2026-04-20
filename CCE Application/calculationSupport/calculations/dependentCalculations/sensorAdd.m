function [outputs, errorCode] = sensorAdd(parameters,inputs)
    %SENSORADD Synthetic calculation created to test calculation dependencies
    %   Adds a constant value to previous sensor value 
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try   
        % Assign Parameters
        constant = parameters.Constant;
%         outputTime = parameters.OutputTime;
        
        % Assign Inputs
        sensorRef = inputs.SensorReference;
        sensorRefTimestamp = inputs.SensorReferenceTimestamps;
        
        outputs.OutputSensor = sensorRef(end) + constant;
        outputs.Timestamp = sensorRefTimestamp(end);
        log.logInfo('Output: %s / %d', string(outputs.Timestamp, "yyyy-MM-dd hh:mm:ss"), outputs.OutputSensor);
        log.logTrace('sensorAdd ran in %s', version('-release'));
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
