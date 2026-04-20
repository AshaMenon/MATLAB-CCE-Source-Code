%% Offgas Exploratory Data Analysis
clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{1};
dataTbl2 = data{2};

%% Get mode proxy
dataTbl = createModeProxy(dataTbl);
indices1 = dataTbl.mode == 'Off';
indices2 = dataTbl.mode == 'Normal';
indices3 = dataTbl.mode == 'Ramp';
indices4 = dataTbl.mode == 'Lost Capacity';

%% Visualisations - Furnace Pressure
tags = {'FurnacePressureA', 'FurnacePressureB', 'FurnacePressureC', 'FurnacePressureD'};
timestamp = dataTbl2.Timestamp;
label = "Furnace Pressure";
data = dataTbl2(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Furnace Pressure')

figure
p5 = plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureA);
hold on
p6 = plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureB);
p7 = plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureC);
p8 = plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureD);

ymin = min([min(dataTbl2.FurnacePressureA), min(dataTbl2.FurnacePressureB),...
    min(dataTbl2.FurnacePressureC), min(dataTbl2.FurnacePressureD)]);
ymax = max([max(dataTbl2.FurnacePressureA), max(dataTbl2.FurnacePressureB),...
    max(dataTbl2.FurnacePressureC), max(dataTbl2.FurnacePressureD)]);
[p1, p2, p3, p4] = shadingClassification(indices1,indices2, indices3, indices4, dataTbl, ymin, ymax);
hold off
legendTxt  = {'Off', 'Normal', 'Ramp', 'Lost Capacity', ...
    'FurnacePressureA', 'FurnacePressureB', 'FurnacePressureC', 'FurnacePressureD'};
legend([p1,p2,p3,p4,p5, p6, p7, p8],legendTxt);

%% Visualisations - SO2 Concentrations
figure
p5 = plot(dataTbl2.Timestamp, dataTbl2.SO2Concentration);
hold on
ymin = 0;
%% 
ymax = max(dataTbl2.SO2Concentration);
[p1, p2, p3, p4] = shadingClassification(indices1,indices2, indices3, indices4, dataTbl, ymin, ymax);
hold off

ylabel('SO2 Concentration');
title('SO2 Concentration to Acid Plant');
legend([p1,p2,p3,p4,p5],'Off', 'Normal', 'Ramp', 'Lost Capacity', 'SO2 Concentration');


%% Smoothing - SO2 Concentration
windowSize = 6 * 60;
furnacePressureA = dataTbl2(:,'SO2Concentration');
furnacePressureA = rmmissing(furnacePressureA);
movingAvg = movmean(dataTbl2.SO2Concentration, windowSize);
gaussianMovingAvg = smoothdata(dataTbl2.SO2Concentration, 'gaussian', window);
medianFiltered = medfilt1(dataTbl2.SO2Concentration, windowSize);
wpass = 0.01;
lowPassFiltered = lowpass(furnacePressureA.SO2Concentration,wpass);

figure
subplot(4,1,1)
plot(dataTbl2.Timestamp, dataTbl2.SO2Concentration, 'b');
hold on
plot(dataTbl2.Timestamp, movingAvg, 'r', 'LineWidth', 1);
legend({'SO2 Concentration', 'Moving Avg'})

subplot(4,1,2)
plot(dataTbl2.Timestamp, dataTbl2.SO2Concentration, 'b');
hold on
plot(dataTbl2.Timestamp, gaussianMovingAvg, 'r', 'LineWidth', 1);
legend({'SO2 Concentration', 'Gaussian'})

subplot(4,1,3)
plot(dataTbl2.Timestamp, dataTbl2.SO2Concentration, 'b');
hold on
plot(dataTbl2.Timestamp, medianFiltered, 'r', 'LineWidth', 1);
legend({'SO2 Concentration','Median'})

subplot(4,1,4)
plot(dataTbl2.Timestamp, dataTbl2.SO2Concentration, 'b');
hold on
plot(furnacePressureA.Timestamp, lowPassFiltered, 'r', 'LineWidth', 1);
hold off
legend({'SO2 Concentration','Low Pass'})
sgtitle('SO2 Concentration to Acid Plant Smoothing')


%% Smoothing - Furnace Pressure
windowSize = 6 * 60;
furnacePressureA = dataTbl2(:,'FurnacePressureA');
furnacePressureA = rmmissing(furnacePressureA);
movingAvg = movmean(dataTbl2.FurnacePressureA, windowSize);
gaussianMovingAvg = smoothdata(dataTbl2.FurnacePressureA, 'gaussian', window);
medianFiltered = medfilt1(dataTbl2.FurnacePressureA, windowSize);
wpass = 0.01;
lowPassFiltered = lowpass(furnacePressureA.FurnacePressureA,wpass);

figure
subplot(4,1,1)
plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureA, 'b');
hold on
plot(dataTbl2.Timestamp, movingAvg, 'r', 'LineWidth', 1);
legend({'Furnace Pressure', 'Moving Avg'})

subplot(4,1,2)
plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureA, 'b');
hold on
plot(dataTbl2.Timestamp, gaussianMovingAvg, 'r', 'LineWidth', 1);
legend({'Furnace Pressure', 'Gaussian'})

subplot(4,1,3)
plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureA, 'b');
hold on
plot(dataTbl2.Timestamp, medianFiltered, 'r', 'LineWidth', 1);
legend({'Furnace Pressure','Median'})

subplot(4,1,4)
plot(dataTbl2.Timestamp, dataTbl2.FurnacePressureA, 'b');
hold on
plot(furnacePressureA.Timestamp, lowPassFiltered, 'r', 'LineWidth', 1);
hold off
legend({'Furnace Pressure','Low Pass'})
sgtitle('Furnace Pressure')
