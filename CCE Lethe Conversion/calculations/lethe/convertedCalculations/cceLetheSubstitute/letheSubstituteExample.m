%% LetheEstimateExample
clear
clc

% substituteData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheSubstitute\letheSubstitute.xlsx'], 'Sheet',2);

substituteData = readtable("substitute.xlsx", 'Sheet', 2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheSubstituteLog";
parameters.CalculationName = "LetheSubstitute";
parameters.CalculationID = "LetheSubstitute01";
parameters.LogLevel =  1;
parameters.OutputTime = "2024-05-24T06:00:01.000Z";

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;
parameters.InputMax = nan;
parameters.InputMin = nan;

parameters.RollupInputs = ["Estimate", "Input", "Ma", "Mog", "Minpas"];

%Get inputs
inputs = struct();

inputs.Ma_2 = substituteData.ma_2(1:64);
inputs.Input_1 = NaN;
inputs.Estimate_5 = NaN;
% inputs.Mog_FT_4T_3 = NaN;
inputs.minpas_4 = substituteData.minpas_4;

inputs.Input_1Timestamps = NaT;
inputs.Ma_2Timestamps = substituteData.ma_2Timestamps(1:64);
inputs.Estimate_5Timestamps = NaT;
% inputs.Mog_FT_4T_3Timestamps = NaT;
inputs.minpas_4Timestamps = substituteData.minpas_4Timestamps;
% Outputs
% expectedOut.Output = substituteData.Output;

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheSubstitute(parameters,inputs);
