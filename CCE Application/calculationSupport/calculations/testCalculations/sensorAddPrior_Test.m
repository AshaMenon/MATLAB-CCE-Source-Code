%% Dependent Calcs Example
%% sensorAddPrior

parameters.LogName = 'sensorAddPrior.log';
parameters.CalculationID = 'senAdd001';
parameters.LogLevel = LogMessageLevel.All;
parameters.CalculationName = 'sensorAddPrior';
parameters.OutputTime = "2021-08-10T16:11:00.000Z";

inputs.Sensor = [67 77 28 24];
inputs.SensorTimestamps = datetime(2021,08,10,16,10,00:10:30);

[outputs, errorCode] = sensorAddPrior(parameters,inputs);

%% sensorAddHistory Calc Server
hostName = 'ons-opcdev:9910';
archive = 'capabilityCalcs';
functionName = 'sensorAddPrior';
numOfOutputs = 2;
functionInputs = {parameters,inputs};
result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
outputs = result{1};
errorCode = cce.CalculationErrorState(result{2});
