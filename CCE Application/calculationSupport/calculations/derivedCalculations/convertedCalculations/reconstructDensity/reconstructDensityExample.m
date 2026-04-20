%% Reconstruct Density Example

% Get Data
dataTbl = readtimetable(fullfile('reconstructDensity_Data.csv'));
parameterTbl = readtable(fullfile('reconstructDensity_Parameters.csv'));
% dataTbl = readtimetable(fullfile('..','..','data','reconstructDensity_Data.csv'));
% parameterTbl = readtable(fullfile('..','..','data','reconstructDensity_Parameters.csv'));
parameters.LogName = parameterTbl.LogName{:};
parameters.CalculationID =  parameterTbl.CalculationID{:};
parameters.LogLevel =  parameterTbl.LogLevel;
parameters.CalculationName =  parameterTbl.CalculationName{:};
parameters.K1 = parameterTbl.K1;
parameters.K2 = parameterTbl.K2;
parameters.K3 = parameterTbl.K3;
parameters.K4 = parameterTbl.K4;
i = 1;
inputs.SolidsFeed = dataTbl.SolidsFeed(i);
inputs.SolidsFeedTimestamps = dataTbl.Timestamps(i);
inputs.SolidsFeedQuality = dataTbl.SolidsFeedQuality(i);
inputs.WaterFeed = dataTbl.WaterFeed(i);
inputs.WaterFeedTimestamps = dataTbl.Timestamps(i);
inputs.WaterFeedQuality = dataTbl.WaterFeedQuality(i);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = reconstructDensity(parameters,inputs);
    
%% MLProdServer Example
hostName = 'ons-mps:9920';
archive = 'derivedCalcs';
functionName = 'reconstructDensity';
functionInputs = {parameters,inputs};
  
numOfOutputs = 1;
output = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);
    