function parameters = AlignFeMatteParams

% Preprocessing data properties

parameters.removeTransientData = true;

parameters.smoothBasicityResponse = false;

parameters.resampleTime = '1min';

parameters.resampleMethod = 'zero';

parameters.subModel = 'Chemistry';

% IO Parameters
parameters.Path = './data/BasicityModel/';

% Logging Parameters
parameters.LogName = 'FeAlignment.log';

parameters.CalculationID = 'TAFM';

parameters.LogLevel = 255;

parameters.CalculationName = 'TestFeAlignment';
end