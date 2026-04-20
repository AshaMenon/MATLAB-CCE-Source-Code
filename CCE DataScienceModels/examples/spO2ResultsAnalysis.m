%% SpO2 Results Analysis

opts = detectImportOptions('temperatureResults_Dec-22.csv');
varNames = opts.VariableNames;
opts = setvartype(opts, varNames(end-1:end), {'double','double'});

liveResults = readtimetable('temperatureResults_Dec-22.csv', opts);
liveResults.Timestamp = datetime(strrep(string(liveResults.Timestamp)',...
    "0022", "2022"));
liveResults.Timestamp = datetime(strrep(string(liveResults.Timestamp)',...
    "0023", "2023"));
% validDateIdx = liveResults.Timestamp > datetime(2022,10,3,12,00,00);
% liveResults = liveResults(validDateIdx, :);
liveResults = rmmissing(liveResults);
% outOfBoundsBasicity = liveResults.Basicity > 2.5 | liveResults.Basicity < 1.1;
% liveResults = liveResults(~outOfBoundsBasicity, :);
% repeatedIdx = [false; diff(liveResults.XGBoostPredictedBasicity) == 0];
% liveResults = liveResults(~repeatedIdx, :);

% liveResults.basicityErrors = liveResults.Basicity - liveResults.XGBoostPredictedBasicity;

%%
figure
plot(liveResults.Timestamp, liveResults.CurrentModelChangeInSpO2, 'x-')
hold on
plot(liveResults.Timestamp, liveResults.DynamicModelChangeInSpO2, 'x-')
legend('Current Model', 'Dynamic Model')