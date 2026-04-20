%% Aligning WACM Fe with Corrected Ni

inputsDF = readAndFormatData('Chemistry');
inputsDF.Timestamp = datetime(inputsDF.Timestamp, 'InputFormat', 'yyyy/MM/dd HH:mm');
inputsDF.Properties.VariableNames = strrep(inputsDF.Properties.VariableNames, " ", "");
inputsDF.Properties.VariableNames = strrep(inputsDF.Properties.VariableNames, "%", "Percentage");

outOfBoundsCorrectedNiSlag = inputsDF.CorrectedNiSlag > 30 | inputsDF.CorrectedNiSlag < 0.2;
inputsDF = inputsDF(~outOfBoundsCorrectedNiSlag, :);
outOfBoundsFeFeedblend = inputsDF.FeFeedblend > 50 | inputsDF.FeFeedblend < 20;
inputsDF = inputsDF(~outOfBoundsFeFeedblend, :);

validDateIdx = inputsDF.Timestamp > datetime(2021,02,26,18,00,00);
inputsDF = table2timetable(inputsDF);
inputsDF = inputsDF(validDateIdx,:);

%% Raw Data
figure
plot(inputsDF.Timestamp, inputsDF.CorrectedNiSlag)
hold on
yyaxis right
plot(inputsDF.Timestamp, inputsDF.FeFeedblend)
legend('Corrected Ni Slag', 'WACM Fe')

figure
plot(inputsDF.CorrectedNiSlag, inputsDF.FeFeedblend, '.')
hold on
xlabel('Corrected Ni Slag')
ylabel('WACM Fe')
title('Correlation = ' + string(corr(inputsDF.CorrectedNiSlag, inputsDF.FeFeedblend)))

%% Resampling Minutely Data with Mean

uniqueFeedblendValueIdx = [false; diff(inputsDF.FeFeedblend) ~= 0];
uniqueFeFeedblend = inputsDF.FeFeedblend(uniqueFeedblendValueIdx);
uniqueTimes = inputsDF.Timestamp(uniqueFeedblendValueIdx);

resampledData = retime(inputsDF(:, 'CorrectedNiSlag'), uniqueTimes, 'mean');
resampledData.FeFeedblend = uniqueFeFeedblend;

figure
plot(resampledData.Timestamp, resampledData.CorrectedNiSlag, 'x-')
hold on
yyaxis right
plot(resampledData.Timestamp, resampledData.FeFeedblend, 'x-')
legend('Corrected Ni Slag', 'WACM Fe')

figure
plot(resampledData.CorrectedNiSlag, resampledData.FeFeedblend, '.')
hold on
xlabel('Corrected Ni Slag')
ylabel('WACM Fe')
title('Correlation = ' + string(corr(resampledData.CorrectedNiSlag, resampledData.FeFeedblend)))

%% Time series decomposition

niSlagModel = TimeSeriesModel(resampledData(:, 'CorrectedNiSlag'));
niSlagModel.decompose()
niSlagModel.plotComponents()
niSlagModel.stationaryTests()
niSlagModel.randomWalkTest()

feFeedblendModel = TimeSeriesModel(resampledData(:, 'FeFeedblend'));
feFeedblendModel.decompose()
feFeedblendModel.plotComponents()
feFeedblendModel.stationaryTests('Raw')
feFeedblendModel.stationaryTests('Res')
feFeedblendModel.randomWalkTest('Raw')
feFeedblendModel.randomWalkTest('Res')

%% Check Corr between stationary series
% According to Stationary tests, Raw Ni Slag is stationary, but
% Raw Fe Feedblend not stationary -> Explore correlations between
% stationary series

figure
plot(niSlagModel.RawData.Timestamp, niSlagModel.RawData.Variables)
hold on
yyaxis right
plot(feFeedblendModel.RawData.Timestamp, feFeedblendModel.Residuals)
legend('Corrected Ni Slag', 'WACM Fe Residuals')

figure
plot(niSlagModel.RawData.Variables, feFeedblendModel.Residuals, '.')
hold on
xlabel('Corrected Ni Slag')
ylabel('WACM Fe Residuals')
title('Correlation = ' + string(corr(niSlagModel.RawData.Variables, feFeedblendModel.Residuals)))

figure
crosscorr(niSlagModel.RawData.Variables, feFeedblendModel.Residuals)

figure
subplot(2,1,1)
autocorr(niSlagModel.RawData.Variables) 
subplot(2,1,2)
autocorr(feFeedblendModel.Residuals)
