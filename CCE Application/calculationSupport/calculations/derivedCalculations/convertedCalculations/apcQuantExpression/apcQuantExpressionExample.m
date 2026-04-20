%% APC Quant Expression Example

% Get Data
dataTbl = readtimetable(fullfile('apcQuantExpression_Data.csv'));
parameterTbl = readtable(fullfile('data','apcQuantExpression_Parameters.csv'));
parameters.LogName = parameterTbl.LogName{:};
parameters.CalculationID =  parameterTbl.CalculationID{:};
parameters.LogLevel =  parameterTbl.LogLevel;
parameters.CalculationName =  parameterTbl.CalculationName{:};
parameters.LogName = "CalculationLog";
parameters.CalculationName = "APC Quant Expression";
parameters.CalculationID = "APC_001";
parameters.DerivedSensorClass = parameterTbl.DerivedSensorClass{:};
parameters.DerivedSensorEU = parameterTbl.DerivedSensorEU;
parameters.DerivedSensorSG = parameterTbl.DerivedSensorSG;
parameters.Expression = parameterTbl.Expression1{:};
parameters.InputSensor1ID = parameterTbl.Sensor1ID{:};
parameters.InputSensor2ID = parameterTbl.Sensor2ID{:} ;
parameters.InputSensor3ID = parameterTbl.Sensor3ID{:} ;
parameters.InputSensor4ID = parameterTbl.Sensor4ID{:} ;
% parameters.Sensor5ID = parameterTbl.Sensor5ID{:} ;
parameters.InputSensor1Eu = parameterTbl.Sensor1Eu{:};
parameters.InputSensor1Sg = parameterTbl.Sensor1Sg;
parameters.InputSensor2Eu = parameterTbl.Sensor1Eu{:};
parameters.InputSensor2Sg = parameterTbl.Sensor1Sg;
parameters.InputSensor3Eu = parameterTbl.Sensor1Eu{:};
parameters.InputSensor3Sg = parameterTbl.Sensor1Sg;
parameters.InputSensor4Eu = parameterTbl.Sensor1Eu{:};
parameters.InputSensor4Sg = parameterTbl.Sensor1Sg;
% parameters.Sensor5Eu = parameterTbl.Sensor1Eu;
% parameters.Sensor5Sg = parameterTbl.Sensor1Sg;

i = 1;
inputs.InputSensor1 = dataTbl.Sensor1Value(i);
inputs.InputSensor1Quality = dataTbl.Sensor1Quality(i);
inputs.InputSensor1Timestamps = dataTbl.Timestamps(i);
inputs.InputSensor1Active = dataTbl.Sensor1Active(i);
inputs.InputSensor1Condition = dataTbl.Sensor1Condition(i);

inputs.InputSensor2 = dataTbl.Sensor2Value(i);
inputs.InputSensor2Quality = dataTbl.Sensor2Quality(i);
inputs.InputSensor2Timestamps = dataTbl.Timestamps(i);
inputs.InputSensor2Active = dataTbl.Sensor2Active(i);
inputs.InputSensor2Condition = dataTbl.Sensor2Condition(i);

inputs.InputSensor3 = dataTbl.Sensor3Value(i);
inputs.InputSensor3Quality = dataTbl.Sensor3Quality(i);
inputs.InputSensor3Timestamps = dataTbl.Timestamps(i);
inputs.InputSensor3Active = dataTbl.Sensor3Active(i);
inputs.InputSensor3Condition = dataTbl.Sensor3Condition(i);

inputs.InputSensor4 = dataTbl.Sensor4Value(i);
inputs.InputSensor4Quality = dataTbl.Sensor4Quality(i);
inputs.InputSensor4Timestamps = dataTbl.Timestamps(i);
inputs.InputSensor4Active = dataTbl.Sensor4Active(i);
inputs.InputSensor4Condition = dataTbl.Sensor4Condition(i);

% inputs.Sensor5Value = dataTbl.Sensor5Value(i);
% inputs.Sensor5Quality = dataTbl.Sensor5Quality(i);
% inputs.Sensor5Timestamps = dataTbl.Timestamps(i);
% inputs.Sensor5Active = dataTbl.Sensor5Active(i);
% inputs.Sensor5Condition = dataTbl.Sensor5Condition(i);

%%   MATLAB Example
% Call Calculation
 [outputs, errorCode] = apcQuantExpression(parameters,inputs);
    
%% MLProdServer Example
hostName = 'ons-mps:9920';
archive = 'derivedCalcs';
functionName = 'apcQuantExpression';
functionInputs = {parameters,inputs};
  
numOfOutputs = 2;
output = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);
    