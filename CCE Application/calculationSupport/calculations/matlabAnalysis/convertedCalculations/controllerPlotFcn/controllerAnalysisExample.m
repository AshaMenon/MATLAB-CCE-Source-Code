%% Controller Analysis Example

% Get Data
filenames = {'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Data.csv',...
    'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Attributes.csv',...
    'Mogn_NIcc_Hpgr_Crush_a406Bn002a_a406Lic405_Parameters.csv'};
startRange = datetime(2020,12,13,1,0,0);
endRange = startRange + hours(1);
timerange = [startRange, endRange];
[parameters,inputs,~,~] =...
        controllerAnalysisMockInterface(filenames, timerange);
   
%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = controllerAnalysis(parameters,inputs);
    
%% MLProdServer Example
hostName = 'ons-mps:9920';
archive = 'controllerAnalysis';
functionName = 'controllerAnalysis';
functionInputs = {parameters,inputs};
  
numOfOutputs = 2;
result = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);
outputs = result.lhs(1).mwdata;
errorCode = result.lhs(2).mwdata;
    