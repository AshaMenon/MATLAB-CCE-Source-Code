function [parameters,inputs, quality, rootCause] =...
        controllerAnalysisMockInterface(filenames, timerange)
    %UNTITLED7 Summary of this function goes here
    %   Detailed explanation goes here
    dataTbl = readtable(fullfile(filenames{1}));
    sensorParameters = readtable(fullfile(filenames{2}));
    parameterTbl = readtable(fullfile(filenames{3}));
    dataTbl.Timestamps = datetime(dataTbl.Timestamps, 'InputFormat', 'yyyy/MM/dd HH:mm');
    dataTbl = dataTbl((dataTbl.Timestamps >= timerange(1) &...
        dataTbl.Timestamps <= timerange(2)),:);
    
    inputs.PV = dataTbl.sensorDataPV_Values;
    inputs.PVTimestamps = dataTbl.Timestamps;
    parameters.PVTrendHigh = sensorParameters.sensorDataPV_TrendHigh(1,1);
    parameters.PVTrendLow = sensorParameters.sensorDataPV_TrendLow(1,1);
    parameters.PVGEDLow = sensorParameters.sensorDataPV_GEDLow(1,1);
    parameters.PVGEDHigh = sensorParameters.sensorDataPV_GEDHigh(1,1);
    parameters.PVHigh = sensorParameters.sensorDataPV_High(1,1);
    parameters.PVLow = sensorParameters.sensorDataPV_Low(1,1);
    
    
    inputs.SP = dataTbl.sensorDataSP_Values;
    varNames = dataTbl.Properties.VariableNames;
    if any(ismember(varNames, 'sensorDataMV_Values'))
        inputs.MV = dataTbl.sensorDataMV_Values;
        parameters.MVTrendHigh = sensorParameters.sensorDataMV_TrendHigh(1,1);
        parameters.MVTrendLow = sensorParameters.sensorDataMV_TrendLow(1,1);
        parameters.MVGEDLow = sensorParameters.sensorDataMV_GEDLow(1,1);
        parameters.MVGEDHigh = sensorParameters.sensorDataMV_GEDHigh(1,1);
        parameters.MVHigh = sensorParameters.sensorDataMV_High(1,1);
        parameters.MVLow = sensorParameters.sensorDataMV_Low(1,1);
        inputs.MVSensorQuality = dataTbl.sensorQualityMV_Values;
        
%     else
%        %sensorDataMV =  struct.empty(0,0);
%        sensorDataMV =  [];
%        sensorQualityMV = [];
    end
    if any(ismember(varNames, 'sensorDataAuto_Values'))
        inputs.Automan = dataTbl.sensorDataAuto_Values(end);
        inputs.AutomanSensorQuality = dataTbl.sensorQualityAuto_Values(end);
%     else
%         %sensorDataAutoman =  struct.empty(0,0);
%         sensorDataAutoman =  [];
%          sensorQualityAutoman = [];
    end
    inputs.PVSensorQuality = dataTbl.sensorQualityPV_Values;
    inputs.SPSensorQuality = dataTbl.sensorQualitySP_Values;
    parameters.Threshold = parameterTbl.Threshold;
    parameters.LogName = parameterTbl.LogName{:};
    parameters.CalculationID = parameterTbl.CalculationID{:};
    parameters.CalculationName =  parameterTbl.CalculationName{:};
    parameters.LogLevel = parameterTbl.LogLevel;
    parameters.ControllerConstraint = parameterTbl.ControllerConstraint{:};
    quality = dataTbl.controllerQuality(end);
    rootCause = dataTbl.rootCause(end);
end

