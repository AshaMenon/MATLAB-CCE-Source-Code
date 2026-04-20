% load("Data\slagLevelData.mat");
% load("Data\modFurnaceData.mat");
% load("Data\massBalanceData.mat");
% load("Data\feedData.mat");
% load("Level Model\trainedModel.mat")

conveyorFlowThreshold = 30;
moisture = 20;
furnaceArea = 31 * 9 * 2.7; % area * slag density

tappedSlag = calculateTappedSlag(massBalanceData, conveyorFlowThreshold, moisture);
[campaignData, outlierThresholds] = generateCampaignData(levelData, furnaceData, tappedSlag, feedData);

timeInterval = minutes(diff(campaignData.timeInterval));
campaignTimeInterval = [timeInterval(:, 1); timeInterval(end, 2)]; %minutes


slagFall = calculateSlagFall(campaignData, furnaceArea);

%Scale all other flow values to ton/min
scaledTappedSlag = campaignData.totalSlagTapped ./ campaignTimeInterval;
scaledFeed = campaignData.totalFeed ./ campaignTimeInterval;

%Compare slag fall, tapped slag and level chancge values.
levelChange = campaignData.levelChange;
comparisonData = table(levelChange, slagFall, scaledTappedSlag);

predictors = [scaledTappedSlag, scaledFeed, campaignData.meanHolderPos, campaignData.meanResistance];
targetVariable = slagFall;

%Consider removing low campaign time durations.
figure()
plot(targetVariable)

lowTimeIdx = campaignTimeInterval <= 9;

predictors(lowTimeIdx, :) = [];
targetVariable(lowTimeIdx) = [];

negIdx = targetVariable < 0;
targetVariable(negIdx) = 0;

%Train model using regression learner app
t = trainedModel.predictFcn(predictors);
figure()
plot(predictors(:, 1) - targetVariable)
hold on
plot(targetVariable)

testData = generateTestData(furnaceData, tappedSlag, feedData, trainedModel, outlierThresholds);

%Test the model using Simulink
[slagIn, slagOut, levels] = generateSimulinkData(testData, levelData);
