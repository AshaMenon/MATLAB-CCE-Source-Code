%% Dependent Calcs Example
%% sensorAdd

parameters.LogName = 'sensorAdd';
parameters.CalculationID = 'senAdd001';
parameters.LogLevel = 4;
parameters.CalculationName = 'Sensor Add';
parameters.Constant = 4;
parameters.OutputTime = datetime(2021,08,24,16,10,30);

inputs.SensorReference = 67;
inputs.SensorReferenceTimestamps = datetime(2021,08,24,16,10,00);

[outputs, errorCode] = sensorAdd(parameters,inputs);

%% sensorAdd Calc Server
hostName = 'ons-mps:9920';
archive = 'dependentCalcs';
functionName = 'sensorAdd';
numOfOutputs = 2;
functionInputs = {parameters,inputs};
result = callMLProdServer(hostName,archive,...
                    functionName, functionInputs, numOfOutputs);
outputs = result.lhs(1).mwdata;
errorCode = result.lhs(2).mwdata;

%% dependentAdd 
clear inputs
clear parameters
parameters.LogName = 'dependentAdd.log';
parameters.CalculationID = 'depAdd001';
parameters.LogLevel = 4;
parameters.CalculationName = 'Dependent Add';

inputs.Sensor1 = 67;
inputs.Sensor1Timestamps = datetime(2021,08,24,16,10,00);
inputs.Sensor2 = 12;
inputs.Sensor3 = 5;
[outputs, errorCode] = dependentAdd(parameters,inputs);