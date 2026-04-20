function parameters = loadParameters()

slddPath = string(which('constants.sldd'));
parameters = loadConstantsFromDictionary(slddPath);
parameters.SlagConveyorMoisture = 0.2;
parameters.MoistureCalibrationPeriod = 2.5; % Period in days over which
% to perform the slag moisture fitting.

parameters.simMode = "simulation";
parameters.LogName = fullfile(getpref('PolokwaneSIL', 'DataFolder'), "logs", "LevelModel.log");
parameters.CalculationID = 'TestLM';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestLevelModel';
parameters.OutputTime = "2024-10-09T08:00:01.000Z";
parameters.SlagConveyorMoisture = 0.2;
parameters.TappingRatePerOpenTapholeTonPerHr  = 1.4*60;
parameters.ExecutionFrequencyParam = 30; % This parameter will need to be renamed (simulation window to return will be more accurate)

parameters.SoundingTimeMin = 6;
parameters.SoundingTimeMax = 7;
parameters.SimulatedMatteLevelLastValue= NaN;
parameters.SimulatedSlagLevelLastValue = NaN;
parameters.SimulatedBlackTopLevelLastValue = NaN;

parameters.lastSimTimestamp = NaN; %TODO incorporate in time - think about this

end