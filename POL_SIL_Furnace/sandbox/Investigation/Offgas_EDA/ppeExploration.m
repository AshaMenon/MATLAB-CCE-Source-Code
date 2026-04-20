%% Positive Pressure Events Exploration

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{1};
dataTbl2 = data{2};
dataTbl3 = data{3};

%% Get mode proxy
dataTbl = createModeProxy(dataTbl);
indices1 = dataTbl.mode == 'Off';
indices2 = dataTbl.mode == 'Normal';
indices3 = dataTbl.mode == 'Ramp';
indices4 = dataTbl.mode == 'Lost Capacity';

%% Initial Visualisation
dataTbl2.mode = dataTbl.mode;
tags = {'PPECount20', 'PPECount50'};
timestamp = dataTbl2.Timestamp;
label = "PPE";
data = dataTbl2(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Positive Pressure Events')
plotTimeseriesWithMode(tags, dataTbl2, 'PPE', 'PPE Count')




%% Rolling PPE Metrics
windowSize
rollingCount20 = movmean(dataTbl2.PPECount20, windowSize);
rollingCount50 = movmean(dataTbl2.PPECount20, windowSize);


%% PPE vs Avg Pressure
avgPressure = mean(dataTbl2(:,{'FurnacePressureA', 'FurnacePressureB', 'FurnacePressureC', 'FurnacePressureD'}), 2);

figure
subplot(2,1,1)
plot(dataTbl2.Timestamp, avgPressure.mean)
hold on
plot(dataTbl2.Timestamp, dataTbl2.PPECount20, 'r', 'LineWidth',1)
yline(0, 'k--');
hold off
legend('Average Pressure', 'PPE Count above 20')

subplot(2,1,2)
plot(dataTbl2.Timestamp, avgPressure.mean)
hold on
plot(dataTbl2.Timestamp, dataTbl2.PPECount50, 'r', 'LineWidth',1)
yline(0, 'k--');
hold off
legend('Average Pressure', 'PPE Count above 50')

%% PPE vs Bone Dry Levels
tags = {'ConcentrateLevelsPort10'
'ConcentrateLevelsPort11'
'ConcentrateLevelsPort2'
'ConcentrateLevelsPort3'
'ConcentrateLevelsPort4'
'ConcentrateLevelsPort5'
'ConcentrateLevelsPort6'
'ConcentrateLevelsPort7'
'ConcentrateLevelsPort8'};

avgLevels = mean(dataTbl3(:,tags), 2);

figure
subplot(2,1,1)
plot(dataTbl.Timestamp, avgLevels.mean)
hold on
plot(dataTbl2.Timestamp, dataTbl2.PPECount20, 'r', 'LineWidth',1)
yline(0, 'k--');
hold off
legend('Average Bone Dry Level', 'PPE Count above 20')

subplot(2,1,2)
plot(dataTbl2.Timestamp, avgLevels.mean)
hold on
plot(dataTbl2.Timestamp, dataTbl2.PPECount50, 'r', 'LineWidth',1)
yline(0, 'k--');
hold off
legend('Average Bone Dry Level', 'PPE Count above 50')

%% Time between PPEs

isTransition = [true; diff(dataTbl2.PPECount20) ~= 0];
transitionTimes = dataTbl2.Timestamp(isTransition);
timeDiffs = diff(transitionTimes);
timeDiffsInMinutes = hours(timeDiffs);

figure;
histogram(timeDiffsInMinutes);
xlabel('Time between PPEs (hours)');
ylabel('Frequency');
title('Distribution of Time between PPE');


figure;
bar(timeDiffsInMinutes);