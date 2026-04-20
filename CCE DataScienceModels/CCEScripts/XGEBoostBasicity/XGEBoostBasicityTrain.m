%% XGEBoost Basicity Model Test

rawInputs = readAndFormatData('Chemistry');

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");
inputs = table2struct(rawInputs, "ToScalar",true);

% setup the parameters
parameters = XGEBoostBasicityParams;
%% Matlab Example
[outputs, errorCode] = TrainXGEBoostBasicityModel(parameters, inputs);

% %% MLProdServer Example
% hostName = 'ons-mps:9920';
% archive = 'bpf_stats';
% functionName = 'bpf_stats';
% functionInputs = {parameters,inputs};
%   
% numOfOutputs = 2;
% result = callMLProdServer(hostName,archive,...
%         functionName, functionInputs, numOfOutputs);