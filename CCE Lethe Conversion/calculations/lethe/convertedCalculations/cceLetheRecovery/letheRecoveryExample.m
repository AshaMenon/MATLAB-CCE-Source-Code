%% LetheRecoveryExample
clear
clc

% recoveryData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
%     '\LetheCalcs\letheRecovery\RecoveryMCABMR4E.xlsx'], 'Sheet',2);
recoveryData = readtable("recovery.xlsx", "Sheet", 2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheRecoveryLog";
parameters.CalculationName = "Lethe Recovery";
parameters.CalculationID = "LetheRecovery01";
parameters.LogLevel =  1;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2024-08-07T11:00:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs (use tab 3)
inputs = table2struct(recoveryData, "ToScalar", true);
% inputs = struct();
% inputs.Waste = recoveryData.Waste;
% inputs.Product = recoveryData.Product;
% inputs.ProductTimestamps = recoveryData.Timestamp;

% % Outputs
% expectedOut.Recovery = recoveryData.Recovery(end-90:end-1);
% expectedOut.Timestamp = recoveryData.Timestamp(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheRecovery(parameters,inputs);

% figure
% subplot(3,1,1)
% stairs(expectedOut.Timestamp, expectedOut.Recovery)
% ylabel('Lethe')
% 
% subplot(3,1,2)
% stairs(outputs.Timestamp, outputs.Recovery)
% ylabel('CCE')
% 
% subplot(3,1,3)
% plot(outputs.Timestamp, outputs.Recovery - expectedOut.Recovery')
% ylabel('Error')

