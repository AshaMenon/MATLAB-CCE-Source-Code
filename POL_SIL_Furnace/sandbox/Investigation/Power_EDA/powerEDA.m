%% Power Exploratory Data Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{1};
resistivityTbl = data{1};

%%
dataTbl = data{5};

% If data files need to be combined

dataTbl = [data{5}(:,data{2}.Properties.VariableNames); data{2}; data{3}; data{4}; data{1}];
dataTbl = sortrows(dataTbl);
dataTbl(1:2,:) = [];



%% Total Power vs SP
tags = {'TotalElectrodePower', 'FurnacePowerSP'};
timestamp = dataTbl.Timestamp;
label = "Power";
data = dataTbl(:, tags);
plotTimeseries(timestamp, data, label, tags, 'Total Power vs SP')

%% Create Mode Proxy
dataTbl = createModeProxy(dataTbl);

%% Visualise Modes

figure
ax1 = subplot(2,1,1);
plot(dataTbl.Timestamp, dataTbl.TotalElectrodePower)
hold on
plot(dataTbl.Timestamp, dataTbl.FurnacePowerSP)
hold off

ax2 = subplot(2,1,2);
plot(dataTbl.Timestamp, dataTbl.mode)

linkaxes([ax1,ax2], 'x')
%%
figure
p5 = plot(dataTbl.Timestamp, dataTbl.TotalElectrodePower);
hold on
p6 = plot(dataTbl.Timestamp, dataTbl.FurnacePowerSP);
indices1 = dataTbl.mode == 'Off';
indices2 = dataTbl.mode == 'Normal';
indices3 = dataTbl.mode == 'Ramp';
indices4 = dataTbl.mode == 'Lost Capacity';
ymin = 0;
ymax = max(dataTbl.TotalElectrodePower);
[p1, p2, p3, p4] = shadingClassification(indices1,indices2, indices3, indices4, dataTbl, ymin, ymax);
hold off

ylabel('Power');
title('Furnace Power vs Power SP');
legend([p1,p2,p3,p4,p5,p6],'Off', 'Normal', 'Ramp', 'Lost Capacity', 'Total Electrode Pwr', 'Furnace Pwr SP');


%% Investigate Furnace Stability
windowSize = 12 * 60;
rollingTimeOnline12 = rollingCumulativeTimeOnline(dataTbl,windowSize);

windowSize = 24 * 60;
rollingTimeOnline24 = rollingCumulativeTimeOnline(dataTbl,windowSize);

windowSize = 48 * 60;
rollingTimeOnline48 = rollingCumulativeTimeOnline(dataTbl,windowSize);

figure
subplot(3,1,1)
plot(dataTbl.Timestamp, rollingTimeOnline12)
title('12 Hour Window')
ylabel('Rolling Metric')
subplot(3,1,2)
plot(dataTbl.Timestamp, rollingTimeOnline24)
title('24 Hour Window')
ylabel('Rolling Metric')
subplot(3,1,3)
plot(dataTbl.Timestamp, rollingTimeOnline48)

sgtitle("Furnace Stability")
title('48 Hour Window')
ylabel('Rolling Metric')

%% Investigate Electrode Immersion
tags = {'Electrode1HolderPosition'
    'Electrode2HolderPosition'
    'Electrode3HolderPosition'
    'Electrode4HolderPosition'
    'Electrode5HolderPosition'
    'Electrode6HolderPosition'};
windowSizeArr = [12, 24, 48];
for j = 1:3
    windowSize = windowSizeArr(j) * 60;
    meanTbl = table();
    stdTbl = table();
    for i = 1:length(tags)
        electrodeData = dataTbl.(tags{i});
       
        [electrodeMean, electrodeStd] = rollingElectrodeImmersion(electrodeData, windowSize);
        meanTbl.("mean_" + string(i)) = electrodeMean;
        stdTbl.('std_' + string(i)) = electrodeStd;
    end
    
    figure
    ax1 = subplot(2,1,1)
    for i = 1:length(tags)
        plot(dataTbl.Timestamp, meanTbl{:,i})
        hold on
    end
    hold off
    legend('Electrode 1', 'Electrode 2', 'Electrode 3', 'Electrode 4', 'Electrode 5', 'Electrode 6')
    title('Rolling Mean for Electrode Holder Position')
    
    ax2 = subplot(2,1,2)
    for i = 1:length(tags)
        plot(dataTbl.Timestamp, stdTbl{:,i})
        hold on
    end
    legend('Electrode 1', 'Electrode 2', 'Electrode 3', 'Electrode 4', 'Electrode 5', 'Electrode 6')
    title('Rolling Std Dev for Electrode Holder Position')
    hold off
    sgtitle([string((windowSize/60)), 'Hour Window'])
    linkaxes([ax1,ax2], 'x')
end

%% Investigate Furnace Stability with Power Only

totalPower = dataTbl.TotalElectrodePower/68;

windowSize = 12 * 60;
rollingTimeOnline12 = movmean(totalPower, windowSize);

windowSize = 24 * 60;
rollingTimeOnline24 = movmean(totalPower, windowSize);

windowSize = 48 * 60;
rollingTimeOnline48 = movmean(totalPower, windowSize);

figure
subplot(3,1,1)
plot(dataTbl.Timestamp, rollingTimeOnline12)
ylim([0,1.2])
title('12 Hour Window')
ylabel('Rolling Metric')
subplot(3,1,2)
plot(dataTbl.Timestamp, rollingTimeOnline24)
ylim([0,1.2])
title('24 Hour Window')
ylabel('Rolling Metric')
subplot(3,1,3)
plot(dataTbl.Timestamp, rollingTimeOnline48)
ylim([0,1.2])

sgtitle("Furnace Stability")
title('48 Hour Window')
ylabel('Rolling Metric')

%% Resistivity vs Holder Positions

tags = {'Electrode1HolderPosition'
    'Electrode2HolderPosition'
    'Electrode3HolderPosition'
    'Electrode4HolderPosition'
    'Electrode5HolderPosition'
    'Electrode6HolderPosition'};

figure
ax1 = subplot(2,1,1);
plot(dataTbl.Timestamp, dataTbl{:, tags});
legend(tags)
title('Electrode Holder Positions')
ax2 = subplot(2,1,2);
plot(resistivityTbl.Timestamp, resistivityTbl{:,:});
title('Resistivity')
linkaxes([ax1 ax2], 'x')

%% Resistivity Outlier Analysis
variablesToAnalyse = ["Resistivity1", "Resistivity2", "Resistivity3"];
fillMethod =  "nearest";
outlierMethod = "movmedian";

resTbl = timetable2table(resistivityTbl);
cleanedTbl = performOutlierAnalysis(resTbl, variablesToAnalyse, "Resistivity1", ...
        fillMethod, outlierMethod);


figure
ax1 = subplot(2,1,1);
plot(dataTbl.Timestamp, dataTbl{:, tags});
legend(tags)
title('Electrode Holder Positions')
ax2 = subplot(2,1,2);
plot(dataTbl.Timestamp, cleanedTbl{:,:});
title('Resistivity')
linkaxes([ax1 ax2], 'x')