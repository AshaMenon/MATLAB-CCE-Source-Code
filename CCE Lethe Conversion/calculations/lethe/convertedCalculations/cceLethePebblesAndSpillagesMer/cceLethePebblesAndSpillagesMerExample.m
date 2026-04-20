%% LethePebblesAndSpillagesMerExample
clear
clc

pnsData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\lethePebblesAndSpillagesMer\PebblesAndSpillagesMer.xlsx'], 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LethePebblesAndSpillagesMerLog";
parameters.CalculationName = "Lethe PebblesAndSpillagesMer";
parameters.CalculationID = "LethePebblesAndSpillagesMer01";
parameters.LogLevel =  3;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-09-27T11:28:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.DryFeedMer = pnsData.DryFeedMer;
inputs.Pebbles = pnsData.Pebbles;
inputs.Run = pnsData.Run;
inputs.Spillages = pnsData.Spillages;
inputs.DryFeedMerTimestamps = pnsData.Timestamp;
inputs.PebblesTimestamps = pnsData.Timestamp;
inputs.SpillagesTimestamps = pnsData.Timestamp;

% Outputs
expectedOut.Output = pnsData.MilledMer(end-90:end-1);
expectedOut.Timestamp = pnsData.Timestamp(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLethePebblesAndSpillagesMer(parameters,inputs);

figure
subplot(3,1,1)
stairs(expectedOut.Timestamp, expectedOut.Output)
ylabel('Lethe')

subplot(3,1,2)
stairs(outputs.Timestamp, outputs.MilledMer)
ylabel('CCE')

subplot(3,1,3)
plot(outputs.Timestamp, outputs.MilledMer - expectedOut.Output')
ylabel('Error')
