%% Catch Error Example

parameters.LogName = 'name';
parameters.CalculationID =  'name';
parameters.LogLevel =  'warning';
parameters.CalculationName =  'errorCalc';
parameters.LogName = "CalculationLog";

inputs.CatchError = false;

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = errorCalc(parameters,inputs);
    
%% MLProdServer Example
hostName = 'ons-mps:9920';
archive = 'derivedCalcs';
functionName = 'errorCalc';
functionInputs = {parameters,inputs};
  
numOfOutputs = 1;
output = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);
    