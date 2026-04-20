%% Levels Multivariate Analysis

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

%% Get Category variables

% Slag
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

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Low', 'Normal', 'High',...
    'Very High','Extremely High'};


levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'slag');
%     tempTbl = table();
%     columnName = [tags{i} 'Cat'];
%     portNumStr = regexp(columnName, 'Port(\d+)', 'tokens');
%     portNumStr = portNumStr{1}{1};  
%     portNum = str2double(portNumStr);
%     tempTbl.portNumber = repmat(portNum, height(levelTbl), 1);
%     tempTbl.category = levelTbl.(columnName);
%     tempTbl.mode = levelTbl.mode;
%     meltedTbl = [meltedTbl; tempTbl];
% 
% end
% 
% scatter(meltedTbl.portNumber, meltedTbl.category, [], meltedTbl.mode);
% 
% scatter(meltedTbl, 'category', 'mode')
% xlabel('Port Number');
% ylabel('Category');
% colorbar;

groupedCounts = groupsummary(levelTbl, {'Port1SlagLevelsCat', 'mode'});
counts = groupedCounts.GroupCount;

heatmapData = unstack(groupedCounts, 'GroupCount', 'mode');
heatmapData(1,:) = [];
heatmapData{:, 2:end} = fillmissing(heatmapData{:, 2:end}, 'constant', 0);
vars = heatmapData.Properties.VariableNames(2:end);
values = heatmapData{:, 2:end};
modeLabels = heatmapData.Port1SlagLevelsCat;

figure;
h = heatmap(vars, modeLabels, values);
h.Colormap = parula;
title('Catgory vs Mode Count: Slag Level')
%%
lvlData = levelTbl{:, tags};
parallelcoords(lvlData);

%% Matte
matteTags = {'Port1MatteLevels'
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

levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'matte');

%% Bonedry
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
levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'bonedry');

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
levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'bath');

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

tags3 = {'Port1MatteBuildLevels'
'Port2MatteBuildLevels'
'Port3MatteBuildLevels'
'Port4MatteBuildLevels'
'Port5MatteBuildLevels'
'Port6MatteBuildLevels'
'Port7MatteBuildLevels'
'Port8MatteBuildLevels'
'Port10MatteBuildLevels'
'Port11MatteBuildLevels'};


levelTbl{:, tags3} = levelTbl{:, tags} + levelTbl{:,tags2};

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Normal', 'High',...
    'Very High','Run Out'};

levelTbl = assignLevelCategories(levelTbl, customOrder, tags, 'matte');

%% Combined Levels

levelTbl = combineLevels(levelTbl);

tbl = levelTbl{:,matteTags};

figure
ax1 = subplot(2,1,1);
stairs(levelTbl.Timestamp, tbl)
ax2 = subplot(2,1,2);
stairs(levelTbl.Timestamp, levelTbl.CombinedMatteLevel)
linkaxes([ax1,ax2], 'x')

%%
figure
plot(levelTbl.Timestamp, levelTbl.AverageSlagLevel)
title('Average Slag Level')

figure
plot(levelTbl.Timestamp, levelTbl.CombinedMatteLevel)
title('Matte Level')

customOrder = {'Undefined', 'Extremely Low','Very Low', 'Low', 'Normal', 'High',...
    'Very High','Extremely High'};

levelTbl = assignLevelCategories(levelTbl, customOrder, {'AverageSlagLevel'}, 'slag');

plotTimeseriesWithMode({'AverageSlagLevel'}, levelTbl, 'Level', 'Slag Level')

plotTimeseriesWithMode({'CombinedMatteLevel'}, levelTbl, 'Level', 'Matte Level')

%%
groupedCounts = groupsummary(levelTbl, {'AverageSlagLevelCat', 'mode'});
counts = groupedCounts.GroupCount;

heatmapData = unstack(groupedCounts, 'GroupCount', 'mode');
heatmapData(1,:) = [];
heatmapData{:, 2:end} = fillmissing(heatmapData{:, 2:end}, 'constant', 0);
vars = heatmapData.Properties.VariableNames(2:end);
values = heatmapData{:, 2:end};
modeLabels = heatmapData.AverageSlagLevelCat;

figure;
h = heatmap(vars, modeLabels, values);
h.Colormap = parula;
title('Catgory vs Mode Count: Slag Level')
