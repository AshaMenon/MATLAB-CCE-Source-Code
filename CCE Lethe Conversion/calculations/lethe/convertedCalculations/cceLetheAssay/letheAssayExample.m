%% LetheAccountabilityExample
clear
clc

assayData = readtable('letheAssayData2.xlsx', 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheAssayLog";
parameters.CalculationName = "Lethe Assay";
parameters.CalculationID = "LetheAssay01";
parameters.LogLevel =  255;

parameters.ComponentIsPercent = true;

parameters.CalculationPeriodsToRun = -45;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2023-11-27T04:00:01.000Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.DryMass = assayData.DryMass(1:end-1);
inputs.Component = assayData.Component;
inputs.ComponentTimestamps = assayData.Timestamp;

% Outputs
% expectedOut.Assay = assayData.Assay;

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheAssay(parameters,inputs);

%  assert(isequal(expectedOut.Assay, outputs.Assay))
