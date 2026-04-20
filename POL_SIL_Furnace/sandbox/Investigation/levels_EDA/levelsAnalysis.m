%% Levels Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{2};
dataTbl2 = data{3};
dataTbl3 = data{1};


%% Combine extra data
data = importData(filename);
dataTbl = [data{1}; data{2}(:,1:62); data{3}; data{4}];
dataTbl = sortrows(dataTbl);
dataTbl(1:2,:) = [];

%% Get mode proxy
dataTbl = createModeProxy(dataTbl);

dataTbl3.mode = dataTbl.mode;

%% Concentrate Levels (Bonedry)
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

data = dataTbl3(:, tags);
visualisePortCounts(data)

%%
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Bone Dry Levels')

% Averages
bonedryLevelAvg = mean(data,2);
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Bone Dry Levels')
hold on
plot(data.Timestamp, bonedryLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

%% Compare with freeboard temps, roof temps

tags = {
'CentreLineThermocouples770E'
'CentreLineThermocouples770H'
'CentreLineThermocouples770K'
'CentreLineThermocouples770C'
'CentreLineThermocouples770D'
'CentreLineThermocouples770F'
'CentreLineThermocouples770G'
'CentreLineThermocouples770I'
'CentreLineThermocouples770J'
'CentreLineThermocouples770L'
'CentreLineThermocouples770A'
'CentreLineThermocouples770B'
'CentreLineThermocouples770W'
'CentreLineThermocouples770X'
'CentreLineThermocouples770M'
'CentreLineThermocouples770N'
'CentreLineThermocouples770O'
'CentreLineThermocouples770P'
'CentreLineThermocouples770Q'
'CentreLineThermocouples770R'
'CentreLineThermocouples770S'
'CentreLineThermocouples770T'
'CentreLineThermocouples770U'
'CentreLineThermocouples770V'
};

plotTimeseriesWithMode(tags, dataTbl, 'Temperature', 'Bone Dry Levels vs Freeboard Temperature')
hold on
plot(data.Timestamp, bonedryLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

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

data = dataTbl3(:, tags);
visualisePortCounts(data)
%plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Matte Levels')

% Averages
matteLevelAvg = mean(data,2);
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Matte Levels')
hold on
plot(data.Timestamp, matteLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

% Check if the values drop due to tapping?

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

data = dataTbl3(:, tags);
visualisePortCounts(data)
%plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Slag Levels')

% Averages
bonedryLevelAvg = mean(data,2);
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Slag Levels')
hold on
plot(data.Timestamp, bonedryLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

% Check if the values drop due to tapping?
%% Total Bath Levels
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

data = dataTbl(:, tags);
visualisePortCounts(data)
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Total Bath Levels')

% Averages
bathLevelAvg = mean(data,2);
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Total Bath Levels')
hold on
plot(data.Timestamp, bathLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

%% Build Up Levels
tags = {'Build_UpLevelsPort1'
'Build_UpLevelsPort2'
'Build_UpLevelsPort3'
'Build_UpLevelsPort4'
'Build_UpLevelsPort5'
'Build_UpLevelsPort6'
'Build_UpLevelsPort7'
'Build_UpLevelsPort8'
'Build_UpLevelsPort10'
'Build_UpLevelsPort11'};

data = dataTbl(:, tags);
%plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Build Up Levels')

visualisePortCounts(data)

% Averages
buildUpLevelAvg = mean(data,2);
plotTimeseriesWithMode(tags, dataTbl3, 'Level', 'Build Up Levels')
hold on
plot(data.Timestamp, buildUpLevelAvg.mean, 'r', 'Linewidth', 1)
lgd = legend;
lgd.String{end} = 'Average';

figure
plot(data.Timestamp, data.Variables)

%% Upsampling

changeIdx = [true; diff(dataTbl3.Port1MatteLevels) ~= 0];

% Extract the timestamps and levels at these indices
changeTimes = dataTbl3.Timestamp(changeIdx);
changeLevels = dataTbl3.Port1MatteLevels(changeIdx);

% Interpolate the values using interp1
interpolatedLevels = interp1(changeTimes, changeLevels, dataTbl3.Timestamp, 'linear');

% Replace the original 'Level' column in the timetable with the interpolated values
dataTbl3.Port1MatteLevels_upsampled = interpolatedLevels;

figure
plot(dataTbl3.Timestamp, dataTbl3.Port1MatteLevels)
hold on
plot(dataTbl3.Timestamp, dataTbl3.Port1MatteLevels_upsampled)

%% Upsampling with Localised Polynomial Smoothing
changeIdx = [true; diff(dataTbl3.Port1MatteLevels) ~= 0];

% Extract the timestamps and levels at these indices
changeTimes = dataTbl3.Timestamp(changeIdx);
changeLevels = dataTbl3.Port1MatteLevels(changeIdx);


% LOESS smoothing
levelLoess = smooth(datenum(changeTimes), changeLevels, 'loess');
loessInterpolated = interp1(changeTimes, levelLoess, dataTbl3.Timestamp, 'linear');

% LOWESS smoothing
levelLowess = smooth(changeLevels, 'lowess');
lowessInterpolated = interp1(changeTimes, levelLowess, dataTbl3.Timestamp, 'linear');

figure
plot(dataTbl3.Timestamp, dataTbl3.Port1MatteLevels)
hold on
plot(dataTbl3.Timestamp, loessInterpolated)
plot(dataTbl3.Timestamp,lowessInterpolated)

%% Electrode Holder Position

tags = {'Electrode1HolderPosition'
    'Electrode2HolderPosition'
    'Electrode3HolderPosition'
    'Electrode4HolderPosition'
    'Electrode5HolderPosition'
    'Electrode6HolderPosition'};
data = dataTbl(:, tags);
electrodeHolderAvg = mean(data,2);

figure
ax1 = subplot(2,1,1);
for i = 1:length(tags)
    plot(dataTbl.Timestamp, dataTbl.(tags{i}))
    hold on
end
legend(tags)
title('Electrode Holder Position')

tags = {'Port1MatteLevels'
'Port10MatteLevels'
'Port11MatteLevels'
'Port2MatteLevels'
'Port3MatteLevels'
'Port4MatteLevels'
'Port5MatteLevels'
'Port6MatteLevels'
'Port7MatteLevels'
'Port8MatteLevels'};

ax2 = subplot(2,1,2);
for i = 1:length(tags)
    plot(dataTbl3.Timestamp, dataTbl3.(tags{i}))
    hold on
end
legend(tags)
title('Matte Levels')
linkaxes([ax1, ax2], 'x')

figure
yyaxis left
plot(matteLevelAvg.Timestamp, matteLevelAvg.mean, 'b','LineWidth', 1)
ylabel('Matte Level Avg')
hold on
yyaxis right
plot(electrodeHolderAvg.Timestamp, electrodeHolderAvg.mean)
ylabel('Electrode Holder Average')
hold off

%% Crusting Analysis

slagTags = {'Port1SlagLevels'
'Port2SlagLevels'
'Port3SlagLevels'
'Port4SlagLevels'
'Port5SlagLevels'
'Port6SlagLevels'
'Port7SlagLevels'
'Port8SlagLevels'
'Port10SlagLevels'
'Port11SlagLevels'};

bonedryTags = {'ConcentrateLevelsPort1'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'
'ConcentrateLevelsPort10'
'ConcentrateLevelsPort11'};

data = dataTbl3(:, [slagTags; bonedryTags]);
time = data.Timestamp;
portList = {'Port1'
'Port2'
'Port3'
'Port4'
'Port5'
'Port6'
'Port7'
'Port8'
'Port10'
'Port11'};

figure
for j = 1:length(bonedryTags)
    ax(j) = subplot(length(bonedryTags)/2, 2, j);
    plot(data.Timestamp, data.(bonedryTags{j}))
    hold on
    plot(data.Timestamp, data.(slagTags{j}))
    title(portList{j})
    ylabel('Level')

    maxValue = max(max(data.(bonedryTags{j})), max(data.(slagTags{j})));

    crusting = (data.(bonedryTags{j}) ~= 0 & (data.(slagTags{j}) == 0 | isnan(data.(slagTags{j}))));
    changePoints = find(diff([0; crusting; 0]));

    for k = 1:length(changePoints)-1
        if crusting(changePoints(k))
            xStart = time(changePoints(k));
            xEnd = time(min(length(time), changePoints(k+1)));  % Ensure not to exceed array bounds
            x = [xStart, xEnd, xEnd, xStart];
            y = [0, 0, maxValue, maxValue];
            fill(x, y, [1, 0.8, 0.8], 'EdgeColor', 'none', 'FaceAlpha', 0.5);

        end
    end
    hold off

end
    linkaxes(ax, 'x')
    legend('Bonedry Level', 'Slag Level')
    sgtitle('Crusting Analysis')


