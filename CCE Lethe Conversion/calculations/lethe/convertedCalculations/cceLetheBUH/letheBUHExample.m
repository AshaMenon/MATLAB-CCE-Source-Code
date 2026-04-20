%% LetheBUHExample
clear
clc

BUHData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheBUH\letheBUH2.xlsx'], 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheBUHLog";
parameters.CalculationName = "Lethe BUH";
parameters.CalculationID = "LetheBUH01";
parameters.LogLevel =  1;
parameters.CalculationPeriodsToRun = -60;

parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-04-12T08:00:01.000Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.Feed = str2double(BUHData.Feed(1:end-6));
% inputs.ProductComp = str2double(BUHData.ProductComp(1:58));
% inputs.WasteComp = str2double(BUHData.WasteComp(1:9));
inputs.ProductComp = str2double(BUHData.Feed);
inputs.WasteComp = str2double(BUHData.Feed);
inputs.FeedTimestamps = BUHData.Timestamps(1:end-6);
inputs.ProductCompTimestamps = BUHData.Timestamps;
inputs.WasteCompTimestamps = BUHData.Timestamps;

% Outputs
% expectedOut.BUH = BUHData.BUH(31:33);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheBUH(parameters,inputs);

%  assert(isequal(expectedOut.BUH, outputs.BUH))
