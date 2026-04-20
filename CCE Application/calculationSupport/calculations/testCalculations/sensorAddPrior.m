function [outputs, errorCode] = sensorAddPrior(parameters,inputs)
    %SENSORADDPRIOR Synthetic calculation created to test calculation output time usage
    %   Sums all historical inputs and outputs them at the output time of the calcualtion.
    %
    %   Set up this calculation with inputs in the past.
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try   
        % Assign Parameters
        outputTime = datetime(parameters.OutputTime,"Format","uuuu-MM-dd'T'HH:mm:ss.SSSZ", ...
            "TimeZone","UTC");
        outputTime.TimeZone="local";
        
        % Compute Outputs - sum eveything in the Input Sensor field

        outputs.Output = sum(inputs.Sensor);
        outputs.Timestamp = outputTime;
        log.logTrace('Output: %s / %.2f', string(outputs.Timestamp, "yyyy-MM-dd hh:mm:ss"), outputs.Output);

    catch err
        outputs.Output = [];
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
