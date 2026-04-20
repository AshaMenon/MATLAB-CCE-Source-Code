%Test Sounding CCE Wrapper

% Load compressed data
% soundingData = importfile1("D:\eunice\Projects\Amplats\SILFurnaceModelling\data\Compressed_Soundings_20241125_2024Aug.xlsx", "Sheet1", [2, Inf]);

soundingData = readtable("D:\eunice\Projects\Amplats\SILFurnaceModelling\data\Compressed_Soundings_20241125_2024Aug.xlsx");

variables = string(soundingData.Properties.VariableNames);

soundingInputs = struct;

for idx = 2:2:length(variables)
    varName = variables(idx);
    timestamps = soundingData{:,idx-1};
    natIdx = isnat(timestamps);

    soundingInputs.(varName) = soundingData{~natIdx, varName};
    soundingInputs.(varName+"Timestamps") = soundingData{~natIdx,idx-1};
end

parameters.SlagConveyorMoisture = 0.2;
parameters.MoistureCalibrationPeriod = 2.5; % Period in days over which
% to perform the slag moisture fitting.

parameters.simMode = "simulation";
parameters.LogName = fullfile(getpref('PolokwaneSIL', 'DataFolder'), "logs", "SoundingCalc.log");
parameters.CalculationID = 'TestLM';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestLevelModel';
parameters.OutputTime = "2024-08-31T22:00:00.000Z";
parameters.SlagConveyorMoisture = 0.2;
parameters.TappingRatePerOpenTapholeTonPerHr  = 1.4*60;
parameters.ExecutionFrequencyParam = 60*24*30; 
%%
[outputs, errorCode] = cceCalcSoundingValuesWrapper(parameters, soundingInputs);

