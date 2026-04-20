%% Linear Basicity Model Test

<<<<<<< Updated upstream
rawInputs = readAndFormatData('Chemistry');

% make it safe to pass to Python
rawInputs.Properties.VariableNames = strrep(rawInputs.Properties.VariableNames, " ", "_");
inputs = table2struct(rawInputs, "ToScalar",true);

% setup the parameters
parameters = LinearBasicityParams;
=======
highFreqPredictors = ["Specific Oxygen Actual PV", ...
    "Specific Silica Actual PV", "Matte feed PV(filtered)", ...
    "Lance oxygen flow rate PV", "Lance air flow rate PV", ...
    "Lance feed PV", "Silica PV", "Lump Coal PV", ...
    "Matte transfer air flow", "Fuel coal feed rate PV"];

lowFreqPredictors = ["Fe Slag", "MgO Slag", "CaO Slag", "SiO2 Slag", ...
    "Al2O3 Slag", "Ni Slag", "S Slag", "S Matte", "Slag temperatures", ...
    "Matte temperatures", "Fe Feedblend", "S Feedblend", ...
    "SiO2 Feedblend", "Al2O3 Feedblend", "CaO Feedblend", ...
    "MgO Feedblend", "Cr2O3 Feedblend", "Corrected Ni Slag", ...
    "Fe Matte"];

predictorTags = [highFreqPredictors, lowFreqPredictors];

responseTags = "Basicity";

inputs = readAndFormatData('Chemistry', responseTags, predictorTags);

% setup the parameters
parameters = struct();

parameters.LogName = 'LinearBasicity';
parameters.CalculationID = 'TLB';
parameters.LogLevel = 'All';
parameters.CalculationName = 'TestLinearBasicity';

parameters.trainFrac = 0.85;
parameters.maxTrainSize = 47*24*60;
parameters.testSize = 7*24*60;
parameters.numIters = 10;

>>>>>>> Stashed changes
%% Matlab Example
[outputs, errorCode] = LinearBasicityModel(parameters, inputs);

% %% MLProdServer Example
% hostName = 'ons-mps:9920';
% archive = 'bpf_stats';
% functionName = 'bpf_stats';
% functionInputs = {parameters,inputs};
%   
% numOfOutputs = 2;
% result = callMLProdServer(hostName,archive,...
%         functionName, functionInputs, numOfOutputs);