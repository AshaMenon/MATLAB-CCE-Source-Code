%% Live Basicity Results

liveResults = readtimetable('chemistryResults_Sep_22-Jan-23.csv');
liveResults.Timestamp = datetime(strrep(string(liveResults.Timestamp)',...
    "0022", "2022"));
liveResults.Timestamp = datetime(strrep(string(liveResults.Timestamp)',...
    "0023", "2023"));
validDateIdx = liveResults.Timestamp > datetime(2022,10,3,12,00,00);
liveResults = liveResults(validDateIdx, :);
liveResults = rmmissing(liveResults);
outOfBoundsBasicity = liveResults.Basicity > 2.5 | liveResults.Basicity < 1.1;
liveResults = liveResults(~outOfBoundsBasicity, :);
repeatedIdx = [false; diff(liveResults.XGBoostPredictedBasicity) == 0];
liveResults = liveResults(~repeatedIdx, :);

liveResults.basicityErrors = liveResults.Basicity - liveResults.XGBoostPredictedBasicity;

%%
figure
histogram(liveResults.Basicity, 'Normalization','probability')
hold on
histogram(liveResults.XGBoostPredictedBasicity, 'Normalization','probability')
legend('Measured Basicity', 'Model Basicity')
ylabel('Probability')
xlabel('Basicity')

[h,p] = kstest2(liveResults.Basicity, liveResults.XGBoostPredictedBasicity);

%% Error Distributions

uniqueBasicityValueIdx = [false; diff(liveResults.Basicity) ~= 0];
uniqueBasicity = liveResults.Basicity(uniqueBasicityValueIdx);
uniqueTimes = liveResults.Timestamp(uniqueBasicityValueIdx);

figure
histogram(liveResults.basicityErrors, 'Normalization', 'probability')
hold on
title('Basicity Errors, Standard Deviation = ' + ...
    string(std(liveResults.basicityErrors)))
ylabel('Probability')
xlabel('Prediction Errors')

figure
cdfplot(liveResults.basicityErrors(uniqueTimes))
[f,x,flo,fup] = ecdf(liveResults.basicityErrors(uniqueTimes));
[~, minIdx] = min(abs(f - 0.025));
[~, maxIdx] = min(abs(f - 0.975));

confidenceSpread = (x(maxIdx) - x(minIdx))/2;

%% Time Series Plots

figure
% plot(liveResults.Timestamp, liveResults.Basicity, '.-')
hold on
plot(uniqueTimes, uniqueBasicity, 'x-')
plot(liveResults.Timestamp, liveResults.XGBoostPredictedBasicity)
legend('Measured Basicity', 'Model Basicity')

%% Error as a function of Basicity

repeatedBModel = fitlm(liveResults.Basicity, liveResults.basicityErrors);

uniqueLinearBModel = fitlm(uniqueBasicity, liveResults.basicityErrors(uniqueTimes));
uniqueQuadraticBModel = fitlm(uniqueBasicity, (liveResults.basicityErrors(uniqueTimes)).^2, 'quadratic');

figure
% plot(liveResults.Basicity, liveResults.basicityErrors, '.')
hold on
plot(uniqueBasicity, (liveResults.basicityErrors(uniqueTimes)).^2, '.')
% plot(liveResults.Basicity, repeatedBModel.predict(liveResults.Basicity))
plot((1.1:0.01:2.4)', uniqueQuadraticBModel.predict((1.1:0.01:2.4)'))
yline(confidenceSpread^2, 'r--')
ylabel('Squared Basicity Error')
xlabel('Basicity')
legend('Error Data', 'Model Fit')

figure
% plot(liveResults.Basicity, liveResults.basicityErrors, '.')
hold on
plot(uniqueBasicity, liveResults.basicityErrors(uniqueTimes), '.')
% plot(liveResults.Basicity, repeatedBModel.predict(liveResults.Basicity))
plot((1.1:0.01:2.4)', uniqueLinearBModel.predict((1.1:0.01:2.4)'))
yline(confidenceSpread, 'r--')
yline(-confidenceSpread, 'r--')
ylabel('Basicity Error')
xlabel('Basicity')
legend('Error Data', 'Model Fit')


linearError = liveResults.basicityErrors(uniqueTimes) - uniqueLinearBModel.predict(uniqueBasicity);
quadraticError = (liveResults.basicityErrors(uniqueTimes)).^2 - uniqueQuadraticBModel.predict(uniqueBasicity);

linearModelFit = sqrt(mean((linearError).^2));
quadraticModelFit = sqrt(mean((quadraticError).^2));

figure
histogram(abs(linearError))
hold on
histogram(sqrt(abs(quadraticError)))
ylabel('Frequency')
xlabel('Error')
legend('Linear Model', 'Quadratic Model')

%% Find index of errors that are "large" -> outside CIs

largeErrorIdx = abs(liveResults.basicityErrors(uniqueTimes)) > confidenceSpread;
silicaForUniqueBasicity = liveResults.SilicaSP(uniqueTimes);
silicaCalculatedSPForUniqueBasicity = liveResults.SpecificSilicaCalculatedSPSP2(uniqueTimes);
silicaOperatorSPForUniqueBasicity = liveResults.SpecificSilicaOperatorSPSP1(uniqueTimes);

figure
ax1 = subplot(4,1,1);
% plot(liveResults.Timestamp, liveResults.Basicity, '.-')
hold on
plot(uniqueTimes, uniqueBasicity, 'x-')
plot(liveResults.Timestamp, liveResults.XGBoostPredictedBasicity)
plot(uniqueTimes(largeErrorIdx), uniqueBasicity(largeErrorIdx), 'ro')
legend('Measured Basicity', 'Model Basicity', 'Outside 95% CI')
xlabel('Timestamp')
ylabel('Basicity')

ax2 = subplot(4,1,2);
% plot(liveResults.Timestamp, liveResults.SpecificSilicaActualPV, '.-')
hold on
plot(liveResults.Timestamp, liveResults.SilicaSP, 'x-')
plot(liveResults.Timestamp, liveResults.SilicaPV, 'x-')
plot(uniqueTimes(largeErrorIdx), silicaForUniqueBasicity(largeErrorIdx), 'ro')
legend('Silica SP', 'Silica PV')

ax3 = subplot(4,1,3);
plot(liveResults.Timestamp, liveResults.SpecificSilicaActualPV, '.-')
hold on
plot(liveResults.Timestamp, liveResults.SpecificSilicaOperatorSPSP1, 'x-')
plot(liveResults.Timestamp, liveResults.SpecificSilicaCalculatedSPSP2, 'x-')
legend('Specific Silica PV', 'Specific Silica (Operator) SP1',...
    'Specific Silica (Calculated) SP2')

ax4 = subplot(4,1,4);
plot(liveResults.Timestamp, liveResults.MatteFeedPV, '.-')
hold on
legend('Matte Feed')
linkaxes([ax1, ax2, ax3, ax4], 'x')

%% Find relationship between magnitude of basicity changes and errors in prediction

basicityChanges = [diff(uniqueBasicity); 0];

figure
plot(abs(basicityChanges), liveResults.basicityErrors(uniqueTimes), '.')
hold on
xlabel('Change in Basicity')
ylabel('Prediction Error')