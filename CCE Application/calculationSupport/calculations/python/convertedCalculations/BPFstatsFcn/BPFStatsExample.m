%% BPF Stats Example

% Get Data
dataTbl = readtimetable(fullfile('BPFStatsData1.csv'));
parameterTbl = readtable(fullfile('BPFStatsParameters.csv'));

parameters.LogName = parameterTbl.LogName{:};
parameters.CalculationID =  parameterTbl.CalculationID{:};
parameters.LogLevel =  parameterTbl.LogLevel;
parameters.CalculationName =  parameterTbl.CalculationName{:};

parameters.InputSensorC80 = parameterTbl.C80;
parameters.InputSensorP75 = parameterTbl.P75;
parameters.InputSensorUCL = parameterTbl.UCL;
parameters.InputSensorLCL = parameterTbl.LCL;
parameters.RunRule = parameterTbl.RunRule;
parameters.ZeroPoints = parameterTbl.ZeroPoints;
parameters.Inverse = parameterTbl.Inverse;
parameters.ExcludeData = parameterTbl.ExcludeData;
parameters.DateAsMatlab = parameterTbl.DateAsMatlab;
parameters.DateAsJS = parameterTbl.DateAsJS;
parameters.InputSensorSensorType = parameterTbl.SensorType{:};
parameters.InputSensorTrendHigh = parameterTbl.TrendHigh;
parameters.InputSensorTrendLow = parameterTbl.TrendLow;
parameters.InputSensorSensorHigh = parameterTbl.SensorHigh;
parameters.InputSensorSensorLow = parameterTbl.SensorLow;
parameters.StandardStd = parameterTbl.StandardStd;

inputs.InputSensor = dataTbl.InputSensor;
inputs.InputSensorTimestamps = dataTbl.Timestamps;
inputs.InputSensorQuality = dataTbl.InputSensorQuality;

%%   MATLAB Example
% Call Calculation
    
[outputs, errorCode] = bpf_stats(parameters,inputs);
    
%% MLProdServer Example
hostName = 'ons-opcdev:9910';
archive = 'bpf_stats';
functionName = 'bpf_stats';
functionInputs = {parameters,inputs};
  
numOfOutputs = 2;
result = callMLProdServer(hostName,archive,...
        functionName, functionInputs, numOfOutputs);
    
% outputs = result.lhs(1).mwdata;
% errorCode = result.lhs(2).mwdata;



