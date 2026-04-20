%% Offgas Outlier Analysis

clear
clc
%% Select data files

selectFile = true;
filename = selectDataFiles(selectFile);

%% Import data into MATLAB and correct timestamp

data = importData(filename);
dataTbl = data{2};
dataTbl2 = data{1};

%% Get mode proxy
dataTbl = createModeProxy(dataTbl);

%% SO2 Concentrations

figure
histogram(dataTbl2.SO2Concentration, Normalization="probability")
title('SO2 Concentration Distribution')

boxplot(dataTbl2.SO2Concentration);

figure
plot(dataTbl.Timestamp, dataTbl2.SO2Concentration)
ylabel('SO2 Concentration')
title('SO2 Concentration')


%% Outlier Detection
[outliers, outlierIndices] = identifyOutliers(dataTbl2.SO2Concentration);

figure
plot(dataTbl.Timestamp, dataTbl2.SO2Concentration)
ylabel('SO2 Concentration')
title('SO2 Concentration')
hold on
plot(dataTbl.Timestamp(outlierIndices), outliers, 'r*', 'MarkerSize', 5)


dataTbl2.SO2Concentration(outlierIndices) = NaN;
dataTbl2.SO2Concentration = fillmissing(dataTbl2.SO2Concentration,'movmedian',5); 

variablesToAnalyse = "SO2Concentration";
fillMethod =  "nearest";
outlierMethod = "movmean";

resTbl = timetable2table(dataTbl2);
cleanedTbl = performOutlierAnalysis(resTbl, variablesToAnalyse, "SO2Concentration", ...
        fillMethod, outlierMethod);




%% Furnace Pressure

figure
histogram(dataTbl2.FurnacePressureA, Normalization="probability")
title('Furnace Pressure Distribution')

figure
boxplot(dataTbl2.FurnacePressureA);

figure
plot(dataTbl.Timestamp, dataTbl2.FurnacePressureA)
ylabel('Pressure')
title('Furnace Pressure')
hold on
plot(dataTbl.Timestamp, dataTbl2.FurnacePressureB)
plot(dataTbl.Timestamp, dataTbl2.FurnacePressureC)
plot(dataTbl.Timestamp, dataTbl2.FurnacePressureD)


legend({'Furnace Pressure A', 'FurnacePressureB', 'FurnacePressureC', 'FurnacePressureD'})



%% Remove and fill high pressures
dataTbl2.FurnacePressureA(dataTbl2.FurnacePressureA >= 99) = NaN;
dataTbl2.FurnacePressureA = fillmissing(dataTbl2.FurnacePressureA, 'Previous');

%% Outlier Detection
[outliers, outlierIndices] = identifyOutliers(dataTbl2.FurnacePressureA);

figure
plot(dataTbl.Timestamp, dataTbl2.FurnacePressureA)
ylabel('Pressure')
title('Furnace Pressure')
hold on
plot(dataTbl.Timestamp(outlierIndices), outliers, 'r*', 'MarkerSize', 5)


dataTbl2.FurnacePressureA(outlierIndices) = NaN;
dataTbl2.FurnacePressureA = fillmissing(dataTbl2.FurnacePressureA,'movmedian',5); 



variablesToAnalyse = "FurnacePressureA";
fillMethod =  "nearest";
outlierMethod = "movmedian";

resTbl = timetable2table(dataTbl2);
cleanedTbl = performOutlierAnalysis(resTbl, variablesToAnalyse, "FurnacePressureA", ...
        fillMethod, outlierMethod);


