%% Resistivity Outlier Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
resistivityTbl = data{1}; % Polokwane_SIL_Resistivity_data_Jan_Aug23_v1.csv
dataTbl = data{2}; % Polokwane_SIL_furnace_data_Jan_Aug23_v3.csv

%% Resistivity vs Holder Positions

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

%% Smoothened Resistivity

tags2 = {"Resistivity1LOESSsmoothed", "Resistivity2LOESSsmoothed", "Resistivity3LOESSsmoothed"};
figure
ax1 = subplot(2,1,1);
plot(dataTbl.Timestamp, dataTbl{:, tags});
legend(tags)
title('Electrode Holder Positions')
ax2 = subplot(2,1,2);
plot(resistivityTbl.Timestamp, resistivityTbl{:,tags2});
title('Resistivity')
linkaxes([ax1 ax2], 'x')