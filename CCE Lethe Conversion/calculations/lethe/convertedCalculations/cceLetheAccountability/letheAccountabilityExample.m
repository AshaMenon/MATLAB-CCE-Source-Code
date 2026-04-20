%% LetheAccountabilityExample
clear
clc

accountabilityData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheAccountability\AccountabilityWTD.xlsx'], 'Sheet',3);

accountabilityData.Timestamp.Hour = 6;
accountabilityData.Timestamp.Minute = 0;
accountabilityData.Timestamp.Second = 1;

%Get parameters

parameters = struct();
parameters.LogName = "LetheAccounatbilityLog";
parameters.CalculationName = "Lethe Accountability";
parameters.CalculationID = "LetheAccountability01";
parameters.LogLevel =  1;
parameters.CalculationPeriodsToRun = -30;

%Get inputs
inputs = struct();
inputs.BUH = accountabilityData.BUH(1:end-6);
inputs.SampleHead = accountabilityData.SampleHead;
inputs.BUHTimestamps = accountabilityData.Timestamp(1:end-6);
inputs.SampleHeadTimestamps = accountabilityData.Timestamp;
parameters.CalculationPeriod = 86400;
parameters.CalculationPeriodOffset = -1;
parameters.OutputTime = "2022-08-17T11:28:45.040Z";
parameters.CalculateAtTime = 21601;

% Outputs
% expectedOut.Accountability = accountabilityData.Accountability(end-89:end);
% expectedOut.Timestamp = accountabilityData.Timestamp(end-89:end);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheAccountability(parameters,inputs);

%  assert(isequal(expectedOut.Accountability, outputs.Accountability))
% 
%  figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Accountability)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Accountability)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Accountability - expectedOut.Accountability')
% ylabel('Error')
