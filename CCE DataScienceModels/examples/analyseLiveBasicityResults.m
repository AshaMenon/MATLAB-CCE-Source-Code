%% Analyse results produced by the deployed model

resultsTbl = readtimetable('chemistryResults_Jan-Mar-23_v1.csv');
resultsTbl.XGBoostPredictedBasicity = str2double(resultsTbl.XGBoostPredictedBasicity);
resultsTbl.RecommendedSpSiSetpoint = fillmissing(str2double(resultsTbl.RecommendedSpSiSetpoint), 'previous');
resultsTbl.DiffInSpSi = fillmissing(str2double(resultsTbl.DiffInSpSi), 'previous');
reducedTable.RequiredChangeInSpSi = fillmissing(str2double(reducedTable.RequiredChangeInSpSi), 'previous');
%%
figure
ax1 = subplot(3,1,1);
title('Basicity and Simulated Basicity')
hold on
plot(resultsTbl.Timestamp, resultsTbl.Basicity)
plot(resultsTbl.Timestamp, resultsTbl.XGBoostPredictedBasicity)
yline(1.75, 'g')
legend('Measured', 'Simulated')

ax2 = subplot(3,1,2);
title('SpSi')
hold on
plot(resultsTbl.Timestamp, resultsTbl.SpecificSilicaActualPV)
plot(resultsTbl.Timestamp, resultsTbl.RecommendedSpSiSetpoint)
legend('SpSi PV', 'SpSi Recommended SP')

ax3 = subplot(3,1,3);
title('Diff in SpSi')
hold on
plot(resultsTbl.Timestamp, resultsTbl.DiffInSpSi)
yline(0, 'k')
linkaxes([ax1, ax2, ax3], 'x')

%% Looking specifically at area of concern
reducedCols = {'XGBoostPredictedBasicity',...
    'RequiredChangeInSpSi','RecommendedSpSiSetpoint',...
    'CulminativeSpSiDiff','SpSiCountValue','DiffInSpSi',...
    'SpecificSilicaActualPV'};
colsToConvert = {'RequiredChangeInSpSi', 'CulminativeSpSiDiff', 'SpSiCountValue'};
reducedTable = resultsTbl(104351-300:2:end,reducedCols);
for nCol = 1:length(colsToConvert)
    columnName = colsToConvert{nCol};
    reducedTable.(columnName) = str2double(reducedTable.(columnName));
end
%%
figure
ax1 = subplot(3,1,1);
plot(reducedTable.Timestamp, reducedTable.XGBoostPredictedBasicity)
hold on
yline(1.75, 'g')
ylabel('Model Basicity')

ax2 = subplot(3,1,2);
plot(reducedTable.Timestamp, reducedTable.RequiredChangeInSpSi)
hold on
yline(0, 'k')
ylabel('SpSi Change')

ax3 = subplot(3,1,3);
plot(reducedTable.Timestamp, reducedTable.DiffInSpSi)
hold on
plot(reducedTable.Timestamp, reducedTable.CulminativeSpSiDiff)
plot(reducedTable.Timestamp(2:5:end), reducedTable.CulminativeSpSiDiff(2:5:end), 'r*')
yline(0, 'k')
ylabel('SpSi Difference')
legend('Difference in SpSi','Cumulative Diff in SpSi')

linkaxes([ax1, ax2, ax3], 'x')

figure
plot(reducedTable.XGBoostPredictedBasicity, reducedTable.RequiredChangeInSpSi, '.')
hold on
yline(0, 'k')
xlabel('Model Basicity')
ylabel('SpSi Change')
