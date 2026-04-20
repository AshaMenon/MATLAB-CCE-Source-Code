%% Combining Levels Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
levelTbl = data{1};

%%

%% Slag Levels
plotCombinedLevel(levelTbl,'SlagLevels', 'Slag Levels')

variableNames = levelTbl.Properties.VariableNames;
slagColumns = contains(variableNames, 'SlagLevels');
slagData = levelTbl{:, slagColumns};
avgSlagValues = calculateLevelAverage(slagData, slagColumns);
levelTbl.avgSlagLevel = avgSlagValues;
levelTbl.avgSlagLevel(levelTbl.avgSlagLevel == 0) = NaN;
levelTbl.avgSlagLevel = fillmissing(levelTbl.avgSlagLevel, 'previous');

yy1 = smooth(x,y,0.1,'loess');
yy2 = smooth(x,y,0.1,'rloess');

changeIdx = [true; diff(levelTbl.avgSlagLevel) ~= 0];

% Extract the timestamps and levels at these indices
changeTimes = levelTbl.Timestamp(changeIdx);
changeLevels = levelTbl.avgSlagLevel(changeIdx);


% LOESS smoothing
levelLoess = smooth(datenum(changeTimes), changeLevels,0.005, 'loess');

levelRLoess = smooth(datenum(changeTimes), changeLevels,0.005, 'rloess');


figure
plot(changeTimes, changeLevels, 'b.')
hold on
plot(changeTimes, levelLoess, '-r')
title('Average Slag Level')


figure
plot(changeTimes, changeLevels, 'b.')
hold on
plot(changeTimes, levelRLoess, '-r')
title('Average Slag Level')

tags = {'avgSlagLevel'};
levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'slag');

figure
histogram(levelTbl.avgSlagLevelCat, 'Normalization','probability')
title('Slag Categorisation')
%% Matte Levels
plotCombinedLevel(levelTbl,'MatteLevels', 'Matte Levels')




%% Build Up Levels
plotCombinedLevel(levelTbl,'Build_UpLevels', 'Build Up Levels')

%% Bonedry Levels
plotCombinedLevel(levelTbl,'ConcentrateLevels', 'Bonedry Levels')
