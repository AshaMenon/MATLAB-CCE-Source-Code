%% LetheAverageExample
clear
clc

% averageData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheAverage\LetheAverageMTD.xlsx'], 'Sheet',2);

averageData = readtable("letheAverage.xlsx", "Sheet", 2);
% Outputs
% expectedOut.Output = averageData.Aggregate(end-89:end);

% [~,ia] = unique(averageData.Input, "stable");
% averageData = averageData(ia, :);

%Get parameters

parameters = struct();
parameters.LogName = "LetheAverageLog";
parameters.CalculationName = "Lethe Average";
parameters.CalculationID = "LetheAverage01";
parameters.LogLevel =  1;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriodOffset = 0;
parameters.ForceToZero = false;
parameters.DataRange = "27.1";
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-08-08T13:00:30.000Z";
parameters.CalculateAtTime = 21601;

%Get inputs
inputs = table2struct(averageData, "ToScalar", true);
% inputs = struct();
% inputs.Input = averageData.Input;
% inputs.InputTimestamps = averageData.Timestamp;


%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheAverage(parameters,inputs);

 % assert(isequal(outputs.Aggregate', expectedOut.Output))
