function createTestData(filename)
    %UNTITLED3 Summary of this function goes here
    %   Detailed explanation goes here
    load(filename, 'description', 'varargin', 'controllerConstraint')
    sensorDataPV_GEDHigh = varargin{1, 2}.Context.Parameters.GEDHigh;
    sensorDataPV_GEDLow = varargin{1, 2}.Context.Parameters.GEDLow;
    sensorDataPV_TrendHigh = varargin{1, 2}.Context.Parameters.TrendHigh;
    sensorDataPV_TrendLow = varargin{1, 2}.Context.Parameters.TrendLow;
    sensorDataPV_High = varargin{1, 2}.Context.Parameters.High;
    sensorDataPV_Low = varargin{1, 2}.Context.Parameters.Low;
    LogName = "controllerAnalysisTestLog";
    CalculationName = "Controller Analysis";
    LogLevel = 255;
 
        if strcmpi(varargin{1, 2}.Context.Type,'APCLevelTransmitter'), Threshold = 4; % controller error %
        elseif strcmpi(varargin{1, 2}.Context.Type,'APCFlowTransmitter'), Threshold = 2; % controller error %
        else Threshold = 8;
        end
   
    ControllerConstraint = {controllerConstraint};
    
    flag = 0;
    
    
    timespanData = originalControllerAnalysis(description, varargin{:});
    if any(ismember(fieldnames(timespanData), 'timeStamps'))
        Timestamps = timespanData.timeStamps{1, 2};
        sensorDataPV_Values = timespanData.plotCntrlData{1, 2}(:,1);
        sensorDataSP_Values = timespanData.plotCntrlData{1, 2}(:,2);
        sensorDataMV_Values = timespanData.plotCntrlData{1, 2}(:,3);
        
        sensorQualityPV_Values	= varargin{1, 2}.Data(2).Quality;
        sensorQualitySP_Values	= varargin{1, 4}.Data(2).Quality;
        
        if isa(varargin{1, 6}, 'struct')
            sensorQualityMV_Values	= varargin{1, 6}.Data(2).Quality;
            sensorDataMV_GEDHigh = varargin{1, 6}.Context.Parameters.GEDHigh;
            sensorDataMV_GEDLow = varargin{1, 6}.Context.Parameters.GEDLow;
            sensorDataMV_TrendHigh = varargin{1, 6}.Context.Parameters.TrendHigh;
            sensorDataMV_TrendLow = varargin{1, 6}.Context.Parameters.TrendLow;
            sensorDataMV_High = varargin{1, 6}.Context.Parameters.High;
            sensorDataMV_Low = varargin{1, 6}.Context.Parameters.Low;
        else
            flag = 1;
            
        end
        
        if isa(varargin{1, 8}, 'struct')
            sensorQualityAuto_Values = varargin{1, 8}.Data(2).Quality;
            sensorDataAuto_Values = timespanData.plotCntrlData{1, 2}(:,4);
        else
            if flag == 1
                flag = 2;
            else
                flag = 3;
            end
        end
        controllerQuality = timespanData.cntrlQuality{1, 2};
        rootCause = timespanData.rootCause{1, 2};
        if flag == 3
            dataTable = table(Timestamps, sensorDataPV_Values,...
                sensorDataSP_Values, sensorDataMV_Values,...
                controllerQuality, rootCause,sensorQualityPV_Values,...
                sensorQualitySP_Values, sensorQualityMV_Values);
            
            sensorAttributes = table(sensorDataPV_TrendHigh, sensorDataPV_TrendLow,...
                sensorDataPV_GEDHigh, sensorDataPV_GEDLow, sensorDataPV_High,...
                sensorDataPV_Low, sensorDataMV_TrendHigh, sensorDataMV_TrendLow,...
                sensorDataMV_GEDHigh, sensorDataMV_GEDLow, sensorDataMV_High, sensorDataMV_Low);
        elseif flag == 1
            dataTable = table(Timestamps, sensorDataPV_Values,...
                sensorDataSP_Values, sensorDataAuto_Values,...
                controllerQuality, rootCause,sensorQualityPV_Values,...
                sensorQualitySP_Values, sensorQualityAuto_Values);
            
            sensorAttributes = table(sensorDataPV_TrendHigh, sensorDataPV_TrendLow,...
                sensorDataPV_GEDHigh, sensorDataPV_GEDLow, sensorDataPV_High,...
                sensorDataPV_Low);
        elseif flag == 2
            dataTable = table(Timestamps, sensorDataPV_Values,...
                sensorDataSP_Values,...
                controllerQuality, rootCause,sensorQualityPV_Values,...
                sensorQualitySP_Values);
            
            sensorAttributes = table(sensorDataPV_TrendHigh, sensorDataPV_TrendLow,...
                sensorDataPV_GEDHigh, sensorDataPV_GEDLow, sensorDataPV_High,...
                sensorDataPV_Low);
        else
            dataTable = table(Timestamps, sensorDataPV_Values,...
                sensorDataSP_Values, sensorDataMV_Values, sensorDataAuto_Values,...
                controllerQuality, rootCause,sensorQualityPV_Values,...
                sensorQualitySP_Values, sensorQualityMV_Values, sensorQualityAuto_Values);
            
            sensorAttributes = table(sensorDataPV_TrendHigh, sensorDataPV_TrendLow,...
                sensorDataPV_GEDHigh, sensorDataPV_GEDLow, sensorDataPV_High,...
                sensorDataPV_Low, sensorDataMV_TrendHigh, sensorDataMV_TrendLow,...
                sensorDataMV_GEDHigh, sensorDataMV_GEDLow, sensorDataMV_High, sensorDataMV_Low);
        end
        dataTable.Timestamps = datetime(dataTable.Timestamps,'ConvertFrom','datenum',...
            'Format','dd/MM/yyyy HH:mm:ss');
        sensorName = char(extractBetween(filename, 'outputs_', '.mat'));
        sensorName = strrep(sensorName, '.', '_');
        CalculationID = {sensorName};
        parameterTbl = table(LogName, CalculationID, CalculationName, LogLevel, Threshold,...
           ControllerConstraint); 
        dataTblName = fullfile('..','..','..','data',[sensorName, '_Data.csv']);
        attributeFileName = fullfile('..','..','..','data',[sensorName, '_Attributes.csv']);
        parameterFile = fullfile('..','..','..','data',[sensorName, '_Parameters.csv']);
        writetable(dataTable, dataTblName)
        writetable(sensorAttributes, attributeFileName)
        writetable(parameterTbl, parameterFile)
        
        if flag ~=0
            disp(sensorName)
        end
    end
end

