%% LethePebblesAndSpillagesUGExample
clear
clc

pnsData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\lethePebblesAndSpillagesUG\PebblesAndSpillagesUG3.xlsx'], 'Sheet',4);

%Get parameters

parameters = struct();
parameters.LogName = "LethePebblesAndSpillagesUGLog";
parameters.CalculationName = "Lethe PebblesAndSpillagesUG";
parameters.CalculationID = "LethePebblesAndSpillagesUG01";
parameters.LogLevel =  3;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-12-06T11:28:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -3;

idx = randperm(height(pnsData), round(height(pnsData)*0.8));

%Get inputs
inputs = struct();
inputs.DryFeedUG1 = pnsData.DryFeedUG1(1:153);
inputs.DryFeedUG2 = pnsData.DryFeedUG2(1:153);
inputs.Pebbles = pnsData.Pebbles;
inputs.Run = NaN;
inputs.Spillages = NaN;
inputs.DryFeedUG1Timestamps = pnsData.Time1(1:153);
inputs.DryFeedUG2Timestamps = pnsData.Time2(1:153);
inputs.PebblesTimestamps = pnsData.Time3;
inputs.SpillagesTimestamps = NaT;

% Outputs
% expectedOut.Output = pnsData.MilledUG1(end-90:end-1);
% expectedOut.Timestamp = pnsData.Timestamp(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLethePebblesAndSpillagesUG(parameters,inputs);

% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Output)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.MilledUG1)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.MilledUG1 - expectedOut.Output')
% ylabel('Error')
