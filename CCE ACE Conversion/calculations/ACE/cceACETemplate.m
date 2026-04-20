function [outputs,errorCode] = cceACETemplate(parameters, inputs)

logger = Logger(parameters.LogName, parameters.CalculationID, ...
    parameters.CalculationName, parameters.LogLevel);

newOutTime = strrep(parameters.OutputTime, "T", " ");
newOutTime = extractBefore(newOutTime, ".");

ExeTime = datetime(newOutTime);

logger.logTrace("Current execution time being used: " + datestr(ExeTime))
errorCode = cce.CalculationErrorState.Good;

try
    % Calculation logic goes here
catch
    
end