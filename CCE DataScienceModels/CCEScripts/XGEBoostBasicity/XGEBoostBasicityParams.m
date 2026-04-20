function parameters = XGEBoostBasicityParams

% Preprocessing data properties

parameters.removeTransientData = true;

parameters.smoothBasicityResponse = true;

parameters.resampleTime = '1min';

parameters.resampleMethod = 'linear';

parameters.subModel = 'Chemistry';

parameters.cleanResponseTags = true;

% split into test and train
parameters.trainFrac = 0.85;

parameters.maxTrainSize = 47*24*60;

parameters.testSize = 7*24*60;

% Crossval Parameters
parameters.numIters = 30;

% evaluation bounding params
parameters.basicityTarget = 1.75;

parameters.deadBand = 0;

parameters.silicaHighMin = 15;
parameters.silicaHighMax = 60;
parameters.silicaLowMin = -60;
parameters.silicaLowMax = -15;

parameters.hoursOff = 8;
parameters.nPeaksOff = 3;
parameters.isOnline = true;
parameters.BlowCountParams = 2;

parameters.BasicityDeltaParam = 0;
parameters.SpSiCountThreshold = 8;

parameters.BasicityLowMid = 1.65;
parameters.BasicityHighMid = 1.85;
parameters.BasicityThresholdMid = 0.03;
parameters.BasicityTimeMid = 6.0;

parameters.BasicityLowMax = 1.5;
parameters.BasicityHighMax = 2.0;
parameters.BasicityThresholdMax = 0.02;
parameters.BasicityTimeMax = 4.0;

parameters.basicityGradientThreshold = 0.00001;

% IO Parameters
parameters.Path = './data/BasicityModel/';

% parameters.pretrainedModelFileName = 'XGEBoost_2021-01-01_01.50.00_to_2021-12-31_23.16.00';

parameters.ModelPath = './data/BasicityModel/2022_XGBoost_Basicity_Model_2022-01-01_05.03.00_to_2022-09-01_00.00 (1).00';
% Logging Parameters
parameters.LogName = 'XGEBoostBasicity.log';

parameters.CalculationID = 'TXGEB';

parameters.LogLevel = 255;

parameters.CalculationName = 'TestXGEBoostBasicity';
end