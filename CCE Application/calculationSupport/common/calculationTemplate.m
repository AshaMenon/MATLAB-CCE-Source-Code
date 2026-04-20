function [outputs, errorCode] = calculationTemplate(parameters,inputs)
    %UNTITLED6 Summary of this function goes here
    %   Detailed explanation goes here
    %   This a template for CCE MATLAB calculations. 
    %   Replace calculationTemplate with the calculation name.
    %   parameters is a struct that includes data that does not have a 
    %   value in time and can be considered constants 
    %   inputs have one or more historical values for a particular
    %   element/attribute based on the output time. 
    
    % Create Log
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = Logger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    % Assign Parameters
    parameter1 = parameters.Parameter1;
    
    % Assign Inputs
    input1 = inputs.Input1;
    
    try
        % Calculation logic goes here 
        outputs.Output1 = input1 * parameter1;
        outputs.Output2 = input2;
    catch err
        outputs.Output1 = [];
        outputs.Output2 = [];
        msg = [err.stack(1).name, ' Line ',...
            num2str(err.stack(1).line), '. ', err.message];
        log.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end
    end
    errorCode = uint32(errorCode);
end

