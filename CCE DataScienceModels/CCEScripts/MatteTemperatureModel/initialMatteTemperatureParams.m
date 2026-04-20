function parameters = initialMatteTemperatureParams(optParamFileName, simMode)
arguments
    optParamFileName char = ''
    simMode char {mustBeMember(simMode, ['simulation', 'production'])} = 'production'
end

% Logging Parameters
parameters.LogName = '.\MatteTemperature.log';
parameters.CalculationID = 'TestMT';
parameters.LogLevel = 255;
parameters.CalculationName = 'TestMatteTemperature';

% Data Formatting Parameters
parameters.removeTransientData = false;
parameters.tapClassification = true;
parameters.smoothFuelCoal = true;

parameters.ModelName = 'fundamentalModel';
parameters.phase = 'B';
parameters.resampleTime = 'minutely';
parameters.resampleMethod = 'next';

if exist('optParamFileName', 'var')
    parameters.optimalParameterFile = optParamFileName;
end

parameters.simMode = simMode;

end