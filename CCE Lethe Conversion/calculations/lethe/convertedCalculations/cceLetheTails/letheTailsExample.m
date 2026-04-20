%% LetheTailsExample
clear; close all
clc
% Tail = 6866.3

%Get parameters
% tailsData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheTails\tailsMCUG22.xlsx'], 'Sheet',2);
tailsData = readtable("tails_settobad.xlsx",'Sheet',2);

parameters = struct();
parameters.LogName = "LetheTails.log";
parameters.CalculationName = "LetheTails";
parameters.CalculationID = "LetheTails01";
parameters.LogLevel = 1;

parameters.CalcLoopLimit = 5;
parameters.CalcBackdays = -7;
parameters.OutputNegTailsAcc = false;
parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-08-07T10:00:01.000Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs based on exec params
inputs = table2struct(tailsData, "ToScalar", true);
inputs.DryFeed = inputs.DryFeed(1:89);
inputs.DryFeedTimestamps = inputs.DryFeedTimestamps(1:89);
% inputs = struct();
% inputs.DryConcentrate = tailsData.DryConcentrate(1:96);
% inputs.DryFeed = tailsData.DryFeed;
% inputs.DryConcentrateTimestamps = tailsData.DryConcentrateTimestamps(1:96);
% inputs.DryFeedTimestamps = tailsData.DryFeedTimestamps;

% Outputs
% expectedOut.Tails = tailsData.Tails;
% expectedOut.negTailsAccumulator = tailsData.negTailsAccumulator;
% inputs.DryConcentrate(30) = 170000; %This value was added to test the negative tails looping functionality.

%  MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheTails(parameters, inputs);

