function testData = generateTestData(furnaceData, tappedSlag, feedData, trainedModel, outlierThresholds)

combinedTable1 = outerjoin(furnaceData, feedData, 'Keys', 'Time', 'MergeKeys', true);

combinedFurnaceData = outerjoin(combinedTable1, tappedSlag, 'Keys', 'Time', 'MergeKeys', true);

%testTemperatures  = mean(combinedFurnaceData{:, 2 : 8}, 2);
testHolderPos = mean(combinedFurnaceData{:, 9 : 14}, 2);
testHolderPos = fillmissing(testHolderPos, "nearest");

%Replace holder position values that fall beyond the threshold values with
%the previous value. 
outlierIdx = find(testHolderPos < outlierThresholds(3) | testHolderPos > outlierThresholds(4));
previousIndex = outlierIdx - 1;
testHolderPos(outlierIdx) = testHolderPos(previousIndex);

testResistance = mean(combinedFurnaceData{:, 19 : 21}, 2);
testResistance = fillmissing(testResistance, "nearest");

%Replace resistance values that fall beyond the threshold values with
%the previous value. 
outlierIdx = find(testResistance < outlierThresholds(1) | testResistance > outlierThresholds(2));
previousIndex = outlierIdx - 1;
testResistance(outlierIdx) = testResistance(previousIndex);

testFeed = combinedFurnaceData.Feed / 60; % ton/min
testFeed = fillmissing(testFeed, "constant", 0);

testTappedSlag = fillmissing(combinedFurnaceData.Conveyor_Slag, "constant", 0);

testPredictors = [testTappedSlag, testFeed, testHolderPos, testResistance];
predictedSlagFall = trainedModel.predictFcn(testPredictors);

Timestamp = combinedFurnaceData.Time;
testData = table(Timestamp, testTappedSlag, testFeed, testHolderPos,...
    testResistance, predictedSlagFall);

