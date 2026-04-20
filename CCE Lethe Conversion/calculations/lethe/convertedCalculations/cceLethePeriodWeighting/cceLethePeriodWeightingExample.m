%% LethePeriodWeightingExample
clear
clc

periodWeightingData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\lethePeriodWeighting\PeriodWeightingComp.xlsx'], 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "PeriodWeightingLog";
parameters.CalculationName = "Lethe PeriodWeightingUG";
parameters.CalculationID = "LethePeriodWeighting01";
parameters.LogLevel =  3;

parameters.CalculationPeriodsToRun = -40;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-09-29T11:28:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.Weight = periodWeightingData.Weight;
inputs.Input = periodWeightingData.Input;
inputs.InputTimestamps = periodWeightingData.InputTime;
inputs.WeightTimestamps = periodWeightingData.WeightTime;

Weighted = periodWeightingData(1:153,{'Weighted','WeightedTime'});

% Outputs
expectedOut.Output = Weighted.Weighted(end-40:end-1);
expectedOut.Timestamp = Weighted.WeightedTime(end-40:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLethePeriodWeighting(parameters,inputs);

figure
subplot(3,1,1)
stairs(expectedOut.Timestamp, expectedOut.Output)
ylabel('Lethe')

subplot(3,1,2)
stairs(outputs.Timestamp, outputs.Weighted)
ylabel('CCE')

subplot(3,1,3)
plot(outputs.Timestamp, outputs.Weighted - expectedOut.Output')
ylabel('Error')
