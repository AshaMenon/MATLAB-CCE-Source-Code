%% LetheEstimateExample
clear
clc

% estimateData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheEstimate\EstimateComp.xlsx'], 'Sheet',2);
%est = 0.1402
estimateData = readtable("estimate.xlsx",'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheEstimateLog";
parameters.CalculationName = "Lethe Estimate";
parameters.CalculationID = "LetheEstimate01";
parameters.LogLevel =  1;
parameters.LastGoodDataPoints = 5;

parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-05-16T10:00:01.000Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = 0;

%Get inputs
inputs = struct();
inputs.Assay = estimateData.Assay(1:33);
inputs.Weighting = estimateData.Weighting;
inputs.AssayTimestamps = estimateData.AssayTimestamps(1:33);
inputs.WeightingTimestamps = estimateData.WeightingTimestamps;

inputs.Assay(end-4:end) = NaN;

% Outputs
% expectedOut.Estimate = estimateData.Estimate(end);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheEstimate(parameters,inputs);

 %%

%  [assay, idx] = getComp(estimateData.Assay);
%  weight = estimateData.Weighting(idx);
% 
%  wl = assay(end-29:end).*weight(end-29:end);
%  totw = sum(weight(end-29:end));
%  est = sum(wl)/totw;

