function [data, startDate, endDate] = sdoTempModelEstimation_Measurement(idx, origTimestamps, origData)
% Simulate the model at the current parameter values and collect experiment
% data

data = origData(idx,:);
timestamps = origTimestamps(idx,:);

%Date range on data
startDate = timestamps(1);
endDate = timestamps(end);

% Edit data so it fits into SL model
data = Data.createDurationIndex(data);

% Preprocessing
data = Data.addFeedsTemperatureData(data);
end
