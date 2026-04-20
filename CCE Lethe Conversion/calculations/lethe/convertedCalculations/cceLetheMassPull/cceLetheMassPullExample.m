%% LetheMassPullExample
clear
clc

massPullData = readtable([getpref('CCECalcDev', 'DataFolder'), ...
    '\LetheCalcs\letheMassPull\LetheMassPull.xlsx'], 'Sheet',2);

%massPullData(end-2,:) = [];

%Get parameters

parameters = struct();
parameters.LogName = "LetheMassPullLog";
parameters.CalculationName = "Lethe MassPull";
parameters.CalculationID = "LetheMassPull01";
parameters.LogLevel =  3;

parameters.CalculationPeriodsToRun = -90;
parameters.CalculationPeriod = 86400;
parameters.OutputTime = "2022-08-19T11:28:45.040Z";
parameters.CalculateAtTime = 21601;

%Get inputs
inputs = struct();
inputs.Product = massPullData.Product;
inputs.Feed = massPullData.Feed;
inputs.ProductTimestamps = massPullData.Timestamp;

% Outputs
expectedOut.Output = massPullData.MassPull(end-89:end);
expectedOut.Timestamp = massPullData.Timestamp(end-89:end);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = cceLetheMassPull(parameters,inputs);

%  assert(isequal(outputs.Aggregate', expectedOut.Output))

figure
subplot(3,1,1)
stairs(expectedOut.Timestamp, expectedOut.Output)
ylabel('Lethe')

subplot(3,1,2)
stairs(outputs.Timestamp, outputs.MassPull)
ylabel('CCE')

subplot(3,1,3)
plot(outputs.Timestamp, outputs.MassPull - expectedOut.Output')
ylabel('Error')
