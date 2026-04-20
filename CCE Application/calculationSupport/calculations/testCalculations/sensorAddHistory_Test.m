%% Dependent Calcs Example
%% sensorAddHistory

parameters.LogName = 'sensorAdd.log';
parameters.CalculationID = 'senAdd001';
parameters.LogLevel = LogMessageLevel.All;
parameters.CalculationName = 'Sensor Add';
parameters.Offset = 4;
parameters.OutputTime = datetime(2021,08,24,16,10,30);

inputs.SensorReference = [67 77];
inputs.SensorReferenceTimestamps = datetime(2021,08,24,16,10,00:10:10);

[outputs, errorCode] = sensorAddHistory(parameters,inputs);

%% sensorAddHistory Calc Server
hostName = 'ons-opcdev:9910';
archive = 'capabilityCalcs';
functionName = 'sensorAddHistory';
numOfOutputs = 2;
functionInputs = {parameters,inputs};
result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
outputs = result.lhs(1).mwdata;
errorCode = result.lhs(2).mwdata;
