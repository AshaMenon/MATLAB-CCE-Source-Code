%% LetheMapReduceExample
clear
clc

mapReduceData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheMapReduce\MapReduceComp.xlsx'], 'Sheet',3);

%Get parameters

parameters = struct();
parameters.LogName = "LetheMapReduceLog";
parameters.CalculationName = "Lethe MapReduce";
parameters.CalculationID = "LetheMapReduce01";
parameters.LogLevel =  3;

parameters.AllowedBadValuesPerPeriod = -1;
parameters.DataRange = "30";
parameters.TotaliserFilter = 0;
parameters.CalculationPeriodsToRun = -60;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-09-22T11:28:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.CountPeriod = mapReduceData.CountPeriod(1:305);
inputs.MeanPeriod = mapReduceData.MeanPeriod(1:305);
inputs.StdDevPeriod = mapReduceData.StdDevPeriod;
inputs.TimePeriod = mapReduceData.TimePeriod(1:153);
inputs.CountPeriodTimestamps = mapReduceData.CountTime(1:305);
inputs.MeanPeriodTimestamps = mapReduceData.MeanPeriodTime(1:305);
inputs.StdDevPeriodTimestamps = mapReduceData.stdDevPeriodTime;
inputs.TimePeriodTimestamps = mapReduceData.TimePeriodTime(1:153);

% Outputs
expectedOut.Mean = mapReduceData.Mean(93:152);
expectedOut.StdDev = mapReduceData.StdDev(93:152);
expectedOut.Timestamp = mapReduceData.MeanTime(93:152);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheMapReduce(parameters,inputs);
% 
% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Mean)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Mean)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Mean - expectedOut.Mean')
% ylabel('Error')
% title("Mean")
% 
% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.StdDev)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.StdDev)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.StdDev - expectedOut.StdDev')
% ylabel('Error')
% title("StdDev")
