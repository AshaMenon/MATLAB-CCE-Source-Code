function parameters = loadMatteTapRatesParameters()

parameters.SlagConveyorMoisture = 0.2;
parameters.MoistureCalibrationPeriod = 2.5; % Period in days over which
% to perform the slag moisture fitting.

parameters.simMode = "simulation";
parameters.LogName = fullfile(getpref('PolokwaneSIL', 'DataFolder'), "logs", "LevelModel.log");
parameters.CalculationID = 'TestLM';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestLevelModel';
parameters.OutputTime = "2024-10-09T08:00:01.000Z";

parameters.relativeTimeRange = 60*60; % Minutes
parameters.ExecutionFrequencyParam = 30; % Minutes
parameters.DefaultLadleWeightTon = 32;
parameters.MinimumTapDurationMins = 10;

parameters.tags = ["Timestamp", "MatteTappedLadleEastTon", ...
    "MatteTappedLadleCenterTon", "MatteTappedLadleWestTon",...
"MatteTapDurationEastSecs", "MatteTapDurationCenterSecs",...
"MatteTapDurationWestSecs", "MatteTap1ThermalCameraTemp",...
"MatteTap2ThermalCameraTemp","MatteTap3ThermalCameraTemp"];

parameters.ladleTags = ["MatteTappedLadleEastTon", ...
    "MatteTappedLadleCenterTon", "MatteTappedLadleWestTon",...
"MatteTapDurationEastSecs", "MatteTapDurationCenterSecs",...
"MatteTapDurationWestSecs"];
end