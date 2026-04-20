function [outputs, errorCode] = calcErrorState(parameters,~)
    %CalcErrorState Calculation for testing Error State behaviour
    %   If parameters.ClearNextOutput is true, sets an empty for next output value, otherwise sets it to parameters.NextOutputValue. 
    %   Sets the LastError to "NextErrorState".
    %
    %   There are no inputs for this calculation.
    
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
        outputs.Timestamp = outputTime;
        
        % Compute Outputs - Based on parameters only
        if (parameters.ClearNextOutput)
            outputs.Output = [];
        else
            outputs.Output = parameters.NextOutputValue;
        end

        errorCode = cce.CalculationErrorState(parameters.NextErrorState);

        log.logTrace('Output: %s / %.2f (%s)', string(outputs.Timestamp, "yyyy-MM-dd hh:mm:ss"), ...
            outputs.Output, string(errorCode));

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
