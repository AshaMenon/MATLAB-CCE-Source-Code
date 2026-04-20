%% Prepare Data Source
rawData = readAndFormatData('Temperature2022');
rawData = timetable2table(rawData);

rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, " ", "");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "%", "Percentage");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "&", "and");

logFile = '.\MatteTemperature.log';
calculationName = 'TestMatteTemperature';
calculationID = 'TestMT';
logLevel = 255;

log = CCELogger(logFile, calculationName, calculationID, logLevel);
log.logInfo('Setting up Data Object')

rawData = table2timetable(rawData);
dataModel = Data(rawData, log);
parameters = initialMatteTemperatureParams();
parameters = getTempModelParameters(parameters, rawData, log);
%%
[origData, ~, ~] = preprocessingAndFeatureEngineering(dataModel,...
    struct('add', false, 'mode',[8]), parameters.resampleTime, ...
    parameters.resampleMethod, parameters.tapClassification, ...
    parameters.smoothFuelCoal, parameters.responseTags, ...
    parameters.referenceTags, parameters.highFrequencyPredictorTags,...
    parameters.lowFrequencyPredictorTags, parameters.phase, false);
log.logInfo(['Data preprocessing completed, final date set size: ' num2str(height(origData))])

%% Training Data
% idx = 1:round(0.75*height(origData)); % Training - Data used in Parameter Estimation
% idx = height(origData)-100000:height(origData); % Testing - Out-of-sample data
% idx = 25367:36608;
data = origData;

%Date range on data
startDate = string(data.Timestamp(1));
endDate = string(data.Timestamp(end));
dates = sprintf('This is data ranging from %s to %s continuously in seconds',startDate,endDate);
disp(dates);


% Edit data so it fits into SL model
data = Data.createDurationIndex(data);

% Preprocessing
data = Data.addFeedsTemperatureData(data);

% Get Variables for Simulation
simVar = getSimvars(data, parameters, log);

%fieldnames to variables
varNames = fieldnames(simVar);
for nVar = 1:numel(varNames)
    eval([varNames{nVar} ' = simVar.' varNames{nVar} ';']);
end

%% Specify inputs for SL Model (new form - root-level inputs)

inputColumnNames = {'MatteFeedTotal', 'FeedRateTot',...
    'TappingClassificationForPhaseMattetapblock1DT_water',...
    'TappingClassificationForPhaseMattetapblock2DT_water',...
    'TappingClassificationForPhaseSlagtapblockDT_water',...
    'Lowerwaffleheatflux', 'CoalFeedRate', 'Upperwaffleheatflux',...
    'FeFeedblend', 'NiFeedblend', 'CoFeedblend', 'CuFeedblend',...
    'Mattetemperatures', 'Slagtemperatures', 'Lanceheight',...
    'LanceOxyEnrichPercentagePV', 'SilicaPV', 'PhaseMattetapblock1DT_water',...
    'PhaseMattetapblock2DT_water', 'PhaseSlagtapblockDT_water'};

slInputs = [seconds(data.Timestamp), data{:, inputColumnNames}];