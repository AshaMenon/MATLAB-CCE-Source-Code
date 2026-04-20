function parameters = LinearBasicityParams

% Preprocessing data properties

parameters.removeTransientData = true;

parameters.smoothBasicityResponse = true;

parameters.addRollingSumPredictors = struct('add', true, 'window', 19);

parameters.addRollingMeanPredictors= struct('add', true, 'window', 5);

parameters.addResponsesAsPredictors= struct('add', true, 'nLags', 3);

parameters.resampleTime = '1min';

parameters.resampleMethod = 'linear';

parameters.subModel = 'Chemistry';
% split into test and train

parameters.trainFrac = 0.85;

parameters.maxTrainSize = 67680;

parameters.testSize = 10080;

parameters.numIters = 10;

parameters.pretrainedModelFileName = 'Linear_2021-01-01_01.50.00_to_2021-12-31_23.16.00';

parameters.LogName = 'LinearBasicity';

parameters.CalculationID = 'TLB';

parameters.LogLevel = 255;

parameters.CalculationName = 'TestLinearBasicity';

parameters.Path = 'data/BasicityModel/';
end