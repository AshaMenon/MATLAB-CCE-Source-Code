%% LetheEstimateExample
clear
clc
% 
% sumData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheSum\LetheSumWTD.xlsx'], 'Sheet',2);

sumData = readtable("letheSumMTD.xlsx",'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheSumLog";
parameters.CalculationName = "LetheSum";
parameters.CalculationID = "LetheSum01";
parameters.LogLevel =  1;

parameters.CalculationPeriodsToRun = -60;
parameters.ForceToZero = false;
parameters.DataRange = "MTD";
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-08-08T12:00:20.000Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = table2struct(sumData, "ToScalar", true);
% inputs = struct();
% inputs.Input = str2double(sumData.Input);
% inputs.InputTimestamps = sumData.InputTimestamps;

% Outputs
% expectedOut.Output = sumData.Aggregate(end-90:end-1);
% expectedOut.Timestamp = sumData.Timestamp(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheSum(parameters,inputs);

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
