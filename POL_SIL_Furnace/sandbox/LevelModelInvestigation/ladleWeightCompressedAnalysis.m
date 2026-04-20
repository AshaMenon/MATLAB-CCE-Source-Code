%% Read data
function ladleWeightCompressedAnalysis()

inputs = readtable("data\Compressed_LadleWeightsDurations_20241129_2024Aug.xlsx");
% inputs.Properties.VariableNames{'Var1'} = 'MatteTappedLadleEastTimestamp';
% inputs.Properties.VariableNames{'Var3'} = 'MatteTappedLadleCenterTimestamp';
% inputs.Properties.VariableNames{'Var5'} = 'MatteTappedLadleWestTimestamp';
%% Create separate timetables
matteTapEastT = inputs(~isnan(inputs.MatteTappedLadleEastTon), 1:2);
matteTapEastT.Properties.VariableNames = ["Timestamp", "Weight"];

matteTapCenterT = inputs(~isnan(inputs.MatteTappedLadleCenterTon), 3:4);
matteTapCenterT.Properties.VariableNames = ["Timestamp", "Weight"];

matteTapWestT = inputs(~isnan(inputs.MatteTappedLadleWestTon), 5:6);
matteTapWestT.Properties.VariableNames = ["Timestamp", "Weight"];
%%
ladleWeights = [matteTapEastT.Weight; matteTapCenterT.Weight; matteTapWestT.Weight];
timestamps = [matteTapEastT.Timestamp; matteTapCenterT.Timestamp; matteTapWestT.Timestamp];
histogram(ladleWeights, BinWidth=1)
title("Ladle weight distribution from compressed data")
xlabel("Ladle weight (tons)")
ylabel("Frequency")

meanLadleWeight = mean(ladleWeights(ladleWeights < 50))
medianLadleWeight = median(ladleWeights)

meanLadleWeight1To10Aug = mean(ladleWeights(timestamps < datetime('11-Aug-2024')))

timestampsSorted = sort(timestamps);
timestampsSortedDiff = diff(timestampsSorted);
histogram(timestampsSortedDiff, BinWidth=minutes(10))


%% Ladle weights over time with trend
startDateTime = datetime('01-Aug-2024');
minutesFromStart = minutes(timestamps - startDateTime);
trend = polyfit(minutesFromStart, ladleWeights, 1);
ytrend = polyval(trend, minutesFromStart);
figure
plot(matteTapEastT.Timestamp, matteTapEastT.Weight, 'o')
hold on
plot(matteTapCenterT.Timestamp, matteTapCenterT.Weight, 'o')
plot(matteTapWestT.Timestamp, matteTapWestT.Weight, 'o')
plot(timestamps, ytrend)
hold off
title("Ladle weights")
xlabel("Timestamp")
ylabel("Ladle weight (tons)")
legend("East", "Center", "West", "Overall trendline")

end