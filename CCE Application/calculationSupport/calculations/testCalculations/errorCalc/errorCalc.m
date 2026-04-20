function [outputs, errorCode] = errorCalc(parameters, inputs)
    %ERRORCALC is used for testing purposes only

    %% Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;

    if ~inputs.CatchError
        %Dont catch error
        error("This was designed to error and not be caught.")
    else
        %Catch error
        try
            error("This was designed to error and be caught.")
        catch err
            outputs.Timestamp = [];
            outputs.OutBool = [];
            msg = [err.stack(1).name, ' Line ',...
                num2str(err.stack(1).line), '. ', err.message];
            log.logError(msg);
            if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
                errorCode = cce.CalculationErrorState.CalcFailed;
            end
        end
    end
    errorCode = uint32(errorCode);
end