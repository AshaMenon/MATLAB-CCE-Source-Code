%% Testing Compiled Version Compared to Script Version

load('D:\John\Projects\AngloAmerican\converter-slag-splash\data\TemperatureModel\Debugging\rawInputsOfflineJanFeb23.mat')
[evalOut, evalErrCode] = EvaluateTemperatureModel(parameters, inputData);

% Write out predictions to Live Predictions Table
evalTable = struct2table(evalOut);
evalTable.Timestamp = datetime(evalTable.Timestamp);
evalTable = table2timetable(evalTable, 'RowTimes', 'Timestamp');

save('compiledOutputs.mat', 'evalTable')