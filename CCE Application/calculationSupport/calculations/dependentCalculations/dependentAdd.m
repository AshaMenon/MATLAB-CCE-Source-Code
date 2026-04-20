function [outputs, errorCode] = dependentAdd(parameters,inputs)
    %SENSORADD Synthetic calculation created to test calculation dependencies
    %   Adds multiple sensor values to get output sensor value
    %   Sensor1 and Sensor2 are compulsory. Additional sensors are optional.
    
        % Create Log
        logFile = parameters.LogName;
        calculationID = parameters.CalculationID;
        logLevel = parameters.LogLevel;
        calculationName = parameters.CalculationName;
        log = CCELogger(logFile, calculationName, calculationID,logLevel);
        errorCode = cce.CalculationErrorState.Good;
    try    
        % Assign Inputs
        outputs.Timestamp = inputs.Sensor1Timestamps;
        inputs = rmfield(inputs, 'Sensor1Timestamps');
        inputNames = fieldnames(inputs);
        sensorNum = length(inputNames);
        
        for i = sensorNum:-1:1
            sensorValues(i,:) =  inputs.(sprintf('Sensor%d',i));
        end
        
        outputs.OutputSensor = sum(sensorValues);
        log.logInfo('Output: %s / %d', string(outputs.Timestamp, "yyyy-MM-dd hh:mm:ss"), outputs.OutputSensor);
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