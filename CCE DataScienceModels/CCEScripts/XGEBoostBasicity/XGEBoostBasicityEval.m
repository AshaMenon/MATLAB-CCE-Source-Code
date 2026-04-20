%% XGEBoost Basicity Model Evaluation

runRange = 1440;
rawInputs = readAndFormatData('sept22Chemistry');
rawInputs = rawInputs(end-(runRange+1000):end,:);
% rawInputs.("Converter mode")(end-120:end) = 1;

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");

outStruct = struct('Timestamp', [],'ProcessSteadyState', [], ...
    'BlowCount', [], 'XGBoostPredictedBasicity', [], ...
    'RequiredChangeInSpSi', [], 'DiffInSpSi', [], ...
    'XGBoostLowerPredictedBasicity', [], ...
    'XGBoostUpperPredictedBasicity', [], ...
    'BasicityDelta', []);

% setup the parameters
parameters = XGEBoostBasicityParams;

parameters.RequiredChangeInSpSiParam = nan;
parameters.BasicityDeltaParam = nan;
parameters.CumulativeSpSiParam = nan;
parameters.SpSiSetpointParam = nan;
parameters.SpSiCountParam = 0;

%% Matlab Example
for endPoint = runRange+1:height(rawInputs)
    tempIn = rawInputs(endPoint-runRange:endPoint,:);
    inputs = table2struct(tempIn, "ToScalar",true);
    inputs.Timestamp = tempIn.Timestamp;

    [outputs, errorCode] = EvaluateBasicityModel(parameters, inputs);

    outStruct = [outStruct, outputs];

    parameters.RequiredChangeInSpSiParam = outputs.RequiredChangeInSpSi;
    parameters.BasicityDeltaParam = outputs.BasicityDelta;
    parameters.CumulativeSpSiParam = outputs.CumulativeSpSi;
    parameters.SpSiSetpointParam = outputs.SpSiSetpoint;
    parameters.SpSiCountParam = outputs.SpSiCount;
end
% %% MLProdServer Example
% hostName = 'ons-mps:9920';
% archive = 'bpf_stats';
% functionName = 'bpf_stats';
% functionInputs = {parameters,inputs};
%   
% numOfOutputs = 2;
% result = callMLProdServer(hostName,archive,...
%         functionName, functionInputs, numOfOutputs);