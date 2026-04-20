%% Call controller Analysis
%% Setup
addpath(fullfile('..','common'));
addpath(fullfile('..','..','..','cce','calculationEventLog'));

%% Load Data & Parameters
dataTbl = readtable(fullfile('..','..','..','mockData','controllerAnalysis.csv'));
parameterTbl = readtable(fullfile('..','..','..','mockData','ParametersControllerAnalysis.csv'));
qualityTbl = readtable(fullfile('..','..','..','mockData','SensorQualityLookUp.csv'));

dataTblRaw = dataTbl;
dataTbl = dataTbl(1:5, :);

sensorDataPV.Values = dataTbl.sensorDataPV_Values;
sensorDataPV.Timestamps = datetime(dataTbl.Timestamp, 'InputFormat', 'yyyy/MM/dd HH:mm');
sensorDataPV.TrendHigh = dataTbl.sensorDataPV_TrendHigh(1,1);
sensorDataPV.TrendLow = dataTbl.sensorDataPV_TrendLow(1,1);
sensorDataPV.GEDLow = dataTbl.sensorDataPV_GEDLow(1,1);
sensorDataPV.GEDHigh = dataTbl.sensorDataPV_GEDHigh(1,1);
sensorDataPV.High = dataTbl.sensorDataPV_High(1,1);
sensorDataPV.Low = dataTbl.sensorDataPV_Low(1,1);

sensorDataSP = dataTbl.sensorDataSP_Values;
sensorDataMV.Values = dataTbl.sensorDataMV_Values;
sensorDataMV.TrendHigh = dataTbl.sensorDataMV_TrendHigh(1,1);
sensorDataMV.TrendLow = dataTbl.sensorDataMV_TrendLow(1,1);
sensorDataMV.GEDLow = dataTbl.sensorDataMV_GEDLow(1,1);
sensorDataMV.GEDHigh = dataTbl.sensorDataMV_GEDHigh(1,1);
sensorDataMV.High = dataTbl.sensorDataMV_High(1,1);
sensorDataMV.Low = dataTbl.sensorDataMV_Low(1,1);

sensorDataAutoman = dataTbl.sensorDataAuto_Values;
sensorQualityPV = dataTbl.sensorQualityPV_Values;
sensorQualitySP = dataTbl.sensorQualitySP_Values;
sensorQualityMV = dataTbl.sensorQualityMV_Values;
sensorQualityAutoman = dataTbl.sensorQualityAuto_Values;
previousControllerQuality = dataTbl.controllerQuality;
qualityValLookUp.GoodQualityVal = qualityTbl.GoodQualityVal;
qualityValLookUp.NotRunningQualityVal  = qualityTbl.NotRunningQualityVal ;
qualityValLookUp.MappedGoodQualityVal = qualityTbl.MappedGoodQualityVal;
parameters.Threshold = parameterTbl.Threshold;
parameters.LogName = parameterTbl.LogName{:};
parameters.CalculationID = parameterTbl.CalculationID{:};
parameters.LogLevel = parameterTbl.LogLevel{:};
parameters.ControllerConstraint = parameterTbl.ControllerConstraint{:};

%% MATLAB Example
[controllerQuality, rootCause] = controllerAnalysis(parameters,...
        sensorDataPV, sensorDataSP, sensorDataMV,sensorDataAutoman,...
        sensorQualityPV, sensorQualitySP, sensorQualityMV,sensorQualityAutoman, ...
        previousControllerQuality, qualityValLookUp);
