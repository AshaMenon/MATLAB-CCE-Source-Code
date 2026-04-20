%% Example to run polokwane SIL funace model and evaluate outputs

% Load data
data = readtable("POL_SIL_Data_20241023_2024AugData.xlsx", "Sheet", "Sheet1");

% filter for 1 week of data
startTime = datetime('01-Aug-2024 15:34:00'); % start when sounding reading has just been taken
endTime = datetime('08-Aug-2024 18:00:00');
data = data(and(data.Timestamp >= startTime, data.Timestamp <= endTime), :);
inputs = table2struct(data,"ToScalar",true); %inputs from CCE will be in a struct

nFeedSamples = 3;
feedDelayHrs = 24;
inputs.MatteFallFraction = calcMatteFallFractionsAve(data, nFeedSamples, feedDelayHrs);

%% Setup Parameters
parameters = loadParameters();

%%

[outputs,errorCode] = ccePolokwaneSILWrapper(parameters, inputs);