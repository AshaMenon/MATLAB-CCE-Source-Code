function [slagIn, slagOut, levels] = generateSimulinkData(testData, levelData)


indexTime = 1 : size(testData, 1);
levelIndexTime = 1 : size(levelData, 1);

slagIn = [indexTime' , testData.predictedSlagFall];
slagOut = [indexTime' , testData.testTappedSlag];
levels = [levelIndexTime', levelData.TotalLevel/100];