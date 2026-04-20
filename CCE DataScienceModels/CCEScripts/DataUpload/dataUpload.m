function [outputs, errorCode] = dataUpload(parameters,inputs)

log = CCELogger(parameters.LogName, parameters.CalculationName, parameters.CalculationID,parameters.LogLevel);

errorCode = CalculationErrorState.Good;

try
    data = readtable(parameters.Path,'VariableNamingRule','preserve');
    %Functionn Outputs
    outputs = table2struct(data,"ToScalar",true);
    outputs.Timestamp = datetime(outputs.Timestamp, 'InputFormat','yyyy/MM/dd HH:mm');

    log.logInfo('Number of Timestamps and columns: %d / %d', numel(outputs.Timestamp), numel(outputs));

    %Error Code
catch err
    msg = [err.stack(1).name,' Line',num2str(err.stack(1).line), '. ', err.message];
    log.logError(msg);
    if errorCode == CalculationErrorState.Good || isempty(errorCode)
        errorCode = CalculationErrorState.CalcFailed;
    end
end
errorCode = uint32(errorCode);
end
