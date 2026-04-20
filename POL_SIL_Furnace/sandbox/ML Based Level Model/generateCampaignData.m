
function [campaignData, outlierThresholds] = generateCampaignData(levelData, furnaceData, tappedSlag, feedData)
%Load the slag level data,


%Find the unique slag level values
slagLevels = removeDuplicateData(levelData);
feedData.Feed = feedData.Feed / 60; %ton/min

%Set all negative feed values to zero
feedData.Feed(feedData.Feed < 0) = 0;

%Pre allocate variables
timeInterval = [datetime("now"), datetime("now")];
totalSlagTapped = zeros(size(slagLevels, 1) - 1, 1);
totalFeed = zeros(size(slagLevels, 1) - 1, 1);
levelChange = zeros(size(slagLevels, 1) - 1, 1);
bottom = zeros(size(slagLevels, 1) - 1, 1);
meanHolderPos = zeros(size(slagLevels, 1) - 1, 1);
meanResistance = zeros(size(slagLevels, 1) - 1, 1);

%The electrode resistances as well as holder positions contain blatant
%outliers. These are cleaned using upper and lower percentiles.

[cleanResistanceTable, ~, lowerResistanceThreshold, upperResistanceThreshold] = ...
    filloutliers(furnaceData,"linear","percentiles",[15 85],...
    "DataVariables",["Electrode1_2Resistance","Electrode3_4Resistance",...
    "Electrode5_6Resistance"]);

[cleanFurnaceData, ~, lowerHolderThreshold, upperHolderThreshold] = ...
    filloutliers(cleanResistanceTable,"linear","percentiles",[10 90],...
    "DataVariables",["Electrode1HolderPosition","Electrode2HolderPosition",...
    "Electrode3HolderPosition","Electrode4HolderPosition",...
    "Electrode5HolderPosition","Electrode6HolderPosition"]);

outlierThresholds = [mean(lowerResistanceThreshold{1, :}), mean(upperResistanceThreshold{1, :}),...
    mean(lowerHolderThreshold{1, :}), mean(upperHolderThreshold{1, :})];
%For each time interval, find the quantity of tapped slag, the quantitity
%of feed, mean resistivity, mean holder positions and thermocouples.
for i = 1 : (size(slagLevels, 1) - 1)

    time1 = slagLevels.Timestamp(i);
    time2 = slagLevels.Timestamp(i + 1);

    nearestTapTime = find(tappedSlag.Time > time1 & tappedSlag.Time < time2);

    nearestFeedTime = find(feedData.Time > time1 & feedData.Time < time2);

    nearestFurnaceDataTime = find(cleanFurnaceData.Time > time1...
        & cleanFurnaceData.Time < time2);

    if isempty(nearestTapTime)
        totalSlagTapped(i) = 0;
    else

        totalSlagTapped(i) = sum(tappedSlag.Conveyor_Slag(nearestTapTime(1) : nearestTapTime(end)));
    end

    if isempty(nearestFeedTime)
        totalFeed(i) = 0;
    else

        totalFeed(i) = sum(feedData.Feed(nearestFeedTime(1) : nearestFeedTime(end)));
    end

    if isempty(nearestFurnaceDataTime)
        %bottom(i+1) = bottom(i);
        %If there is no recorded furnace data for the time interval, use
        %the last known values.

        meanHolderPos(i) = meanHolderPos(i - 1);
        meanResistance(i) = meanResistance(i - 1);
    else

        %bottom(i + 1) = mean(cleanFurnaceData{furnaceDataTime(1) : furnaceDataTime(end), 2:8}, 'all');
        meanHolderPos(i) = mean(cleanFurnaceData{nearestFurnaceDataTime(1) : nearestFurnaceDataTime(end), 9:14}, 'all');
        meanResistance(i) = mean(cleanFurnaceData{nearestFurnaceDataTime(1) : nearestFurnaceDataTime(end), 19:21}, 'all');
    end

    levelChange(i) = slagLevels.TotalLevel(i+1) - slagLevels.TotalLevel(i);

    timeInterval(i, 1) = time1;
    timeInterval(i, 2) = time2;
end

meanResistance = fillmissing(meanResistance, "previous");
meanHolderPos = fillmissing(meanHolderPos, "previous");

campaignData = table(timeInterval, levelChange, totalFeed, totalSlagTapped, meanHolderPos, meanResistance);
