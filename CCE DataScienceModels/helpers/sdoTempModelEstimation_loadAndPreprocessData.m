function [origData, timestamps, parameters] = sdoTempModelEstimation_loadAndPreprocessData(log)

% Prepare Data Source
rawData = readAndFormatData('Temperature2023');
rawData = timetable2table(rawData);

rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, " ", "");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "%", "Percentage");
rawData.Properties.VariableNames = strrep(rawData.Properties.VariableNames, "&", "and");

log.logInfo('Setting up Data Object')

rawData = table2timetable(rawData);
timestamps = rawData.Timestamp;
dataModel = Data(rawData, log);

optParamFileName = 'optParams21June2023.xml'; % or empty char, '', 'optParams15-Sep-0022015000.xml'
simMode = 'simulation'; % or 'production'

parameters = initialMatteTemperatureParams(optParamFileName, simMode);
parameters = getTempModelParameters(parameters, rawData, log);

[origData, ~, ~] = preprocessingAndFeatureEngineering(dataModel,...
    struct('add', false, 'mode',[8]), parameters.resampleTime, ...
    parameters.resampleMethod, parameters.tapClassification, ...
    parameters.smoothFuelCoal, parameters.responseTags, ...
    parameters.referenceTags, parameters.highFrequencyPredictorTags,...
    parameters.lowFrequencyPredictorTags, parameters.phase, false);
log.logInfo(['Data preprocessing completed, final date set size: ' num2str(height(origData))])
end