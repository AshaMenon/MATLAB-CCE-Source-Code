%% Levels Categorisation
clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
levelTbl = data{1};
dataTbl = data{2};


%% Get mode proxy
dataTbl = createModeProxy(dataTbl);

levelTbl.mode = dataTbl.mode;

%% Filter out Off Data

levelTbl = levelTbl(levelTbl.mode ~= "Off", :);
levelTbl = levelTbl(~isundefined(levelTbl.mode), :);

%% Slag Levels
tags = {'Port1SlagLevels'
'Port2SlagLevels'
'Port3SlagLevels'
'Port4SlagLevels'
'Port5SlagLevels'
'Port6SlagLevels'
'Port7SlagLevels'
'Port8SlagLevels'
'Port10SlagLevels'
'Port11SlagLevels'};

tags = {'avgSlagLevel'};

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Low', 'Normal', 'High',...
    'Very High','Extremely High'};


grey = [0.5, 0.5, 0.5];
blue1 = [0.6505,0.8725,0.9665];
blue2 = [0.3010 0.7450 0.9330];
blue3 = [0 0.4470 0.7410];
green = [0.4660 0.6740 0.1880];
red1 = [0.9290 0.6940 0.1250];
red2 = [0.8500 0.3250 0.0980];
red3 = [0.6350 0.0780 0.1840];
red4 = [1 0 0];

customColourmap = [grey; blue1; blue2; blue3; green; red1; red2; red3];

[percentageMatrix, ~] = categoriseLevels(tags,levelTbl, 'slag', customOrder);
plotLevelCategorisation( 'Slag', customColourmap, percentageMatrix,...
        customOrder)

%% Matte Levels
tags = {'Port1MatteLevels'
'Port2MatteLevels'
'Port3MatteLevels'
'Port4MatteLevels'
'Port5MatteLevels'
'Port6MatteLevels'
'Port7MatteLevels'
'Port8MatteLevels'
'Port10MatteLevels'
'Port11MatteLevels'};

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Normal', 'High',...
    'Very High','Run Out'};

customColourmap = [grey; blue2; blue3; green; red1; red2; red3];

[percentageMatrix, ~] = categoriseLevels(tags, levelTbl, 'matte', customOrder);
plotLevelCategorisation( 'Matte', customColourmap, percentageMatrix,...
        customOrder)

%% Bonedry Levels
tags = {'ConcentrateLevelsPort1'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'
'ConcentrateLevelsPort10'
'ConcentrateLevelsPort11'};

customOrder = {'Undefined', 'Low', 'Normal', 'High','Extremely High'};

customColourmap = [grey; blue3; green; red2; red3];

[percentageMatrix, ~] = categoriseLevels(tags,levelTbl, 'bonedry', customOrder);
plotLevelCategorisation( 'Bonedry', customColourmap, percentageMatrix,...
        customOrder)

%% Bath Levels
tags = {'Port1TotalBathLevels'
'Port2TotalBathLevels'
'Port3TotalBathLevels'
'Port4TotalBathLevels'
'Port5TotalBathLevels'
'Port6TotalBathLevels'
'Port7TotalBathLevels'
'Port8TotalBathLevels'
'Port10TotalBathLevels'
'Port11TotalBathLevels'};

customOrder = {'Undefined', 'Low', 'Normal', 'High',...
    'Very High','Above Waffe Coolers', 'Extremely High'};

customColourmap = [grey; blue3; green; red1; red2; red3; red4];

[percentageMatrix, ~] = categoriseLevels(tags,levelTbl, 'bath', customOrder);
plotLevelCategorisation( 'Bath', customColourmap, percentageMatrix,...
        customOrder)

%% Matte + Build-Up

tags = {'Port1MatteLevels'
'Port2MatteLevels'
'Port3MatteLevels'
'Port4MatteLevels'
'Port5MatteLevels'
'Port6MatteLevels'
'Port7MatteLevels'
'Port8MatteLevels'
'Port10MatteLevels'
'Port11MatteLevels'};

tags2 = {'Build_UpLevelsPort1'
'Build_UpLevelsPort2'
'Build_UpLevelsPort3'
'Build_UpLevelsPort4'
'Build_UpLevelsPort5'
'Build_UpLevelsPort6'
'Build_UpLevelsPort7'
'Build_UpLevelsPort8'
'Build_UpLevelsPort10'
'Build_UpLevelsPort11'};

lvlTbl2 = levelTbl;
lvlTbl2{:, tags} = levelTbl{:, tags} + levelTbl{:,tags2};

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Normal', 'High',...
    'Very High','Run Out'};

customColourmap = [grey; blue2; blue3; green; red1; red2; red3];

[percentageMatrixMatteBuild, ~] = categoriseLevels(tags, lvlTbl2, 'matte', customOrder);
plotLevelCategorisation( 'Matte + Build Up', customColourmap, percentageMatrixMatteBuild,...
        customOrder)


