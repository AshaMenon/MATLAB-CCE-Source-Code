function [outputs, errorCode,simOut] = MatteTemperatureModel(parameters,inputs)

try
    [outputs, error_code] = EvaluateTemperatureModel(parameters, inputs);

catch err
    % TODO: Handle errors

end
% Convert errorCode to uint32 for MATLAB Production Server
errorCode = uint32(error_code);
end