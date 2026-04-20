function parameters = loadMatteFallParameters()

parameters.simMode = "simulation";
parameters.LogName = fullfile(getpref('PolokwaneSIL', 'DataFolder'), "logs", "LevelModel.log");
parameters.CalculationID = 'TestLM';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestLevelModel';
parameters.OutputTime = "2024-10-09T08:00:01.000Z";
parameters.SlagConveyorMoisture = 0.2;
parameters.TappingRatePerOpenTapholeTonPerHr  = 1.4*60;

parameters.relativeTimeRange = 60*60; % Minutes
parameters.ExecutionFrequencyParam = 30; % Minutes

parameters.NSamples = 3;
parameters.DelayHrs = 24;

parameters.tags = ["Timestamp", "FeedS", "FeedCr2O3", "FeedAl2O3", ...
    "FeedCaO", "FeedCo", "FeedCu", "FeedFe", "FeedMgO", "FeedNi", "FeedSiO2"];

end