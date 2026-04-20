%% LethePeriodAverageExample
clear
clc

periodAverageData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\periodAverage\PeriodAverage2.xlsx'], 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LethePeriodAverage2Log";
parameters.CalculationName = "Lethe PeriodAverage";
parameters.CalculationID = "LethePeriodAverage01";
parameters.LogLevel =  1;

parameters.CalculationPeriodsToRun = -30;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-04-04T08:00:00.000Z";
parameters.CalculateAtTime = 21601;
parameters.ForceTimeCollation = false;
parameters.CalculationPeriodOffset = -1;
parameters.ForceToZero = false;

parameters.AdditionalInputs = ["UG21"];

%Get inputs
inputs = struct();
inputs.Input = periodAverageData.Input;
inputs.UG21 = periodAverageData.Input;
% inputs.UG22 = periodAverageData.Input;

inputs.InputTimestamps = periodAverageData.Timestamp;
inputs.UG21Timestamps = periodAverageData.Timestamp;
% inputs.UG22Timestamps = periodAverageData.Timestamp;

% Outputs
% expectedOut.Output = periodAverageData.Aggregate(end-90:end-1);
% expectedOut.Timestamp = periodAverageData.Timestamp(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLethePeriodAverage(parameters,inputs);

 % diff = expectedOut.Output - outputs.Aggregate';

%  assert(isequal(outputs.Aggregate', expectedOut.Output))

% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Output)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Aggregate)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Aggregate - expectedOut.Output')
% ylabel('Error')
