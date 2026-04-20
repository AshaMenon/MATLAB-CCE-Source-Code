%% ComponentArrayExample
clear
clc

%Get parameters

parameters = struct();
parameters.LogName = "ComponentLog";
parameters.CalculationName = "Component";
parameters.CalculationID = "CompArr01";
parameters.LogLevel =  1;

parameters.ComponentIsPercent = false;
parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-08-19T15:59:59Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

componentData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheComponent\component.xlsx'], 'Sheet',2);

componentData.Timestamp.Hour = 6;
componentData.Timestamp.Minute = 0;
componentData.Timestamp.Second = 1;

inputs.Assay = componentData.Assay(1:end-6);
inputs.AssayTimestamps = componentData.Timestamp(1:end-6);
inputs.DryMassTimestamps = componentData.Timestamp(1:end-3);
inputs.EstimateTimestamps = NaT;
inputs.DryMass = componentData.DryMass(1:end-3);
inputs.Estimate = NaN;

% Outputs
% expectedOut.Component = componentData.Component(end-89:end);
% expectedOut.Timestamp = componentData.Timestamp(end-89:end);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheComponent(parameters,inputs);
    
% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Component)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Component)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Component - expectedOut.Component')
% ylabel('Error')