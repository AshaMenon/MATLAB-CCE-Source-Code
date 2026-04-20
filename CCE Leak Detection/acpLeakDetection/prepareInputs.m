function [Inputs, Config, ModelPerformance] = prepareInputs(inputs, parameters)
% PREPAREINPUTS takes input data for the wrapper function  
% and prepares into desirable format. 
% 
% inputs: struct of input data 
% parameters: struct of PI Parametres

%% Fields
inputFields = fieldnames(inputs);
timestampIdx = contains(inputFields,{'Timestamps', 'Timestamp'});
timestampFields = string(inputFields(timestampIdx));
features_uniq = unique(string(inputFields(~timestampIdx)),'stable');

for feature = features_uniq'
    if iscell(inputs.(feature))
        inputs.(feature) = cellfun(@formatCell,inputs.(feature));
    end
end

paramFields = string(fieldnames(parameters));
featuresParamsIdx = contains(paramFields,features_uniq);
featuresParams = paramFields(featuresParamsIdx);
featuresSize = size(features_uniq,1);

%% Parameters
% Config
Config = ["timestamp", "timestamp", -1, 0, 0, -1, 0, -1, -1];
for f = 1:featuresSize
    featureParamsIdx = contains(featuresParams, features_uniq(f));
    featureParams = featuresParams(featureParamsIdx);
     % FeatureName_Phase_Digital
    featureName_phase_digital = features_uniq(f);
    % Tag
    tagParam = featureName_phase_digital;
    % Smoothing & Outlier detection
    cleaningParams = featureParams;
    for i = 1:size(cleaningParams,1)
    cleaningValues(i,1) = parameters.(cleaningParams(i));
    end
    % FeatureName_Phase_Digital
    featureName_phase_digital = split(featureName_phase_digital,"_");
    config = [tagParam; featureName_phase_digital; cleaningValues ]';
    Config = [Config;config];
end
vars = ["Tag", "Feature","Phase","Digital","F_GrossOutlierDetection",...
    "F_GrossOutlierDetection_k","F_Smoothing","F_Smoothing_p","F_Smoothing_a"];
Config = array2table(Config,"VariableNames",vars);
Config = convertvars(Config,vars(3:end),'double');
% Parameter Data types
factorParams = extractBefore(parameters.FactorTypeTags,"_");
factorParamsIdx = contains(Config{:,"Feature"},factorParams);
Config.Type(factorParamsIdx) = "factor";
Config.Type(~factorParamsIdx) = "numeric";
Config.Type(Config.Tag == "timestamp") = "time";

% ModelPerformance
modelPerformanceParamsIdx = contains(paramFields,"ModelPerformance");
modelPerformanceParams = paramFields(modelPerformanceParamsIdx);
ModelPerformance = [];

for m = 1:size(modelPerformanceParams,1)
modelPerformanceValue = parameters.(modelPerformanceParams(m));
ModelPerformance = [ModelPerformance ; modelPerformanceValue];
end
modelPerformanceVars = extractAfter(modelPerformanceParams,"ModelPerformance_")';
ModelPerformance = array2table(ModelPerformance',"VariableNames",modelPerformanceVars);
%% Inputs
Inputs = [];
tags_reference = [Config.Tag, Config.Feature];
for i = 1:featuresSize
tagLength = size(inputs.(features_uniq(i)),1);
tagIdx = contains(tags_reference(:,1), features_uniq(i));
tags = repelem(tags_reference(tagIdx,1),tagLength)';
stacked = table(tags, inputs.(timestampFields(i)) , inputs.(features_uniq(i)));
Inputs = [Inputs; stacked];
end
vars = {'Tag','Timestamp','Value'};
Inputs = renamevars(Inputs,Inputs.Properties.VariableNames,vars);
Inputs.Timestamp = Inputs.Timestamp - hours(2);
%TODO: Remove this for prod
%Remove missing
%Inputs = rmmissing(Inputs);
Inputs.Value(isnan(Inputs.Value)) = 0;
Inputs = table2cell(Inputs);
end

function out = formatCell(in)
    switch lower(in)
        case "on"
            out = 1;
        case "off"
            out = 0;
        otherwise
            out = nan;
    end
end