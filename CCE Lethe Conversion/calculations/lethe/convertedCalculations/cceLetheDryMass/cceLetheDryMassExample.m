%% LetheDryMassExample
clear
clc

dryMassData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheDryMass\DryMassComp.xlsx'], 'Sheet',2);

%Get parameters

parameters = struct();
parameters.LogName = "LetheDryMassLog";
parameters.CalculationName = "Lethe DryMass";
parameters.CalculationID = "LetheDryMass01";
parameters.LogLevel =  3;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-09-22T11:28:45.040Z";
parameters.CalculateAtTime = 21601;
parameters.CalculationPeriodOffset = -1;

%Get inputs
inputs = struct();
inputs.Estimate = dryMassData.Estimate;
inputs.Moisture = dryMassData.Moisture(1:66);
inputs.WetMass = dryMassData.WetMass(1:152);
inputs.EstimateTimestamps = dryMassData.Var3;
inputs.MoistureTimestamps = dryMassData.Var5(1:66);
inputs.WetMassTimestamps = dryMassData.Var7(1:152);

% Outputs
expectedOut.Output = dryMassData.DryMass(end-90:end-1);
expectedOut.Timestamp = dryMassData.Var1(end-90:end-1);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheDryMass(parameters,inputs);

%  assert(isequal(outputs.Aggregate', expectedOut.Output))

figure
subplot(3,1,1)
stairs(expectedOut.Timestamp, expectedOut.Output)
ylabel('Lethe')

subplot(3,1,2)
stairs(outputs.Timestamp, outputs.DryMass)
ylabel('CCE')

subplot(3,1,3)
plot(outputs.Timestamp, outputs.DryMass - expectedOut.Output')
ylabel('Error')
