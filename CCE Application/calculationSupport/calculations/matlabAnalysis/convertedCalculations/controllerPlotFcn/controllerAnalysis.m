function [outputs, errorCode] = controllerAnalysis(parameters, inputs)
    
    %inputs:struct with the following fields:
    %    PV: Double [n x 1]
    %    PVTimestamps: Datetime [n x 1]
    %    MV: Double [n x 1] (Optional)
    %    SP: Double [n x 1] (optional)
    %    Automan: Double [1 x 1]
    %    PVSensorQuality: Double [n x 1]
    %    MVSensorQuality: Double [n x 1]
    %    SPSensorQuality: Double [n x 1]
    %    AutomanSensorQuality: Double [n x 1]
    
    %Parameters:
    %   ControllerConstraint
    %   Threshold: if sensor type = 'APCLevelTransmitter', Threshold = 4
    %   if sensor type = 'APCFlowTransmitter', Threshold = 2, else Threshold = 8
    %   PVTrendHigh: Double [1 x 1]
    %   PVTrendLow: Double [1 x 1]
    %   PVGEDLow: Double [1 x 1]
    %   PVGEDHigh: Double [1 x 1]
    %   PVHigh: Double [1 x 1]
    %   PVLow: Double [1 x 1]
    %   MVTrendHigh: Double [1 x 1]
    %   MVTrendLow: Double [1 x 1]
    %   MVGEDLow: Double [1 x 1]
    %   MVGEDHigh: Double [1 x 1]
    %   MVHigh: Double [1 x 1]
    %   MVLow: Double [1 x 1]
    %   LogName
    %   CalculationID
    %   LogLevel
    %   CalculationName
    
    %outputs:
    %   controllerQuality: Double [1x1], can be a value from 1-5
    %       1 - Instrument Fault
    %       2 - Manual
    %       3 - Internal Error
    %       4 - Unhealthy
    %       5 - Healthy
    %   rootCause: Double [1x1], can be a value from 0-5
    %       0 - Controller healthy, so there's no root cause
    %       1 - Saturation
    %       2 - Disturbance/Slow Control
    %       3 - Disturbance/Fast Inner Loop
    %       4 - Valve Stiction/Pump Problem
    %       5 - Cause Unknown
    
    logFile = parameters.LogName;
    calculationID = parameters.CalculationID;
    logLevel = parameters.LogLevel;
    calculationName = parameters.CalculationName;
    log = CCELogger(logFile, calculationName, calculationID,logLevel);
    errorCode = cce.CalculationErrorState.Good;
    
    try
        % Manipulate Inputs
        threshold = parameters.Threshold;
        controllerConstraint = parameters.ControllerConstraint;
        
        goodQualityVal = DataQuality.Good;
        notRunningQualityVal = DataQuality.NotRunning;
        mappedGoodQualityVal = DataQuality.MappedGood;
        
        pvLow = parameters.PVLow;
        pvHigh = parameters.PVHigh;
        pvGEDLow = parameters.PVGEDLow;
        pvGEDHigh = parameters.PVGEDHigh;
        pvTrendLow = parameters.PVTrendLow;
        pvTrendHigh = parameters.PVTrendHigh;
        mvLow = parameters.MVLow;
        mvHigh = parameters.MVHigh;
        mvGEDLow = parameters.MVGEDLow;
        mvGEDHigh = parameters.MVGEDHigh;
        mvTrendLow = parameters.MVTrendLow;
        mvTrendHigh = parameters.MVTrendHigh;
        
        if ~isnumeric(threshold) || ~(ischar(controllerConstraint)|| isstring(controllerConstraint))
            err = MException('InputValidation:InputTypeNotValid', ...
                'Input type not valid');
            errorCode = cce.CalculationErrorState.BadInput;
            throw(err)
        end

    executingMfilename = 'ControllerPlotAnalysis:';
    errorMessage = [];
        
        pvSensor = inputTranslation(inputs.PV, inputs.PVSensorQuality,...
            inputs.PVTimestamps);
        spSensor = inputTranslation(inputs.SP,...
            inputs.SPSensorQuality,inputs.PVTimestamps);
        
        sensorsInd = [~isempty(inputs.PV) ~isempty(inputs.SP),...
            (isfield(inputs,'MV')&& ~isempty(inputs.MV)),... 
            (isfield(inputs,'Automan')&& ~isempty(inputs.Automan))];
    
        
        if sensorsInd(3)
            if ~isfield(inputs,'MVSensorQuality')
                 err = MException('controllerAnalysis:MissingData', ...
                'Quality Data Missing');
                errorCode = cce.CalculationErrorState.NoData;
                throw(err)
            end
            mvSensor = inputTranslation(inputs.MV,inputs.MVSensorQuality,...
                inputs.PVTimestamps);
        else
            mvSensor = struct.empty(0,0);
        end
        
        if sensorsInd(4)
            if ~isfield(inputs,'AutomanSensorQuality')
                err = MException('controllerAnalysis:MissingData', ...
                    'Quality Data Missing');
                errorCode = cce.CalculationErrorState.NoData;
                throw(err)
            end
            automanSensor = inputTranslation(inputs.Automan,...
                inputs.AutomanSensorQuality,inputs.PVTimestamps);
        else
            automanSensor = struct.empty(0,0);
        end
        
        sensorData = {pvSensor, spSensor, mvSensor, automanSensor};
        emptyTimespanIndex = [cellfun(@isempty,{sensorData{1}.Value}) cellfun(@isempty,{sensorData{2}.Value})];
        
        % Check if critical sensors contrains data
        if any(emptyTimespanIndex) && isempty(errorMessage)
            if sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(1) == 1
                errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV');
                errorCode = cce.CalculationErrorState.NoData;
                throw(errorMessage)
            elseif sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(2) == 1
                errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: SP');
                errorCode = cce.CalculationErrorState.NoData;
                throw(errorMessage)
            else
                errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV & SP');
                errorCode = cce.CalculationErrorState.NoData;
                throw(errorMessage)
            end
        end
        
        % Perform Analysis
        for i = 1:length(sensorsInd)
            if sensorsInd(i)~=0 && ~any([sensorData{i}.IsEmpty])
                sensor(i).Data = {sensorData{i}.Value}; %#ok
                sensor(i).Quality = {sensorData{i}.Quality}; %#ok
                sensor(i).TimeStamp = {sensorData{i}.TimeStamp}; %#ok
                sensor(i).TimeStep = {sensorData{i}.TimeStep}; %#ok
                sensor(i).Length = {sensorData{i}.Length}; %#ok
                if i == 4 % If auto mode we need to replace missing data with last good value
                    for k = 1:length(sensor(i).Data)
                        % Replace missing data with last good value
                        if any(isnan(sensor(i).Data{k}))
                            [sensor(i).Data{k},sensor(i).Quality{k}] = ...
                                replaceMissingData(sensor(i).Data{k},...
                                sensor(i).Quality{k},goodQualityVal);
                        end
                    end
                end
                
            elseif i == 3 && sensorsInd(i)==0
                % Assume output NaN's
                for k = 1:length(sensor(1).Data)
                    sensor(i).Data{k} = NaN(size(sensor(1).Data{k},1),1);
                    sensor(i).Quality{k} = goodQualityVal*ones(size(sensor(1).Quality{k},1),1);
                    sensor(i).TimeStamp{k} = {sensorData{1}.TimeStamp};
                end
            elseif i == 4 && sensorsInd(i)==0
                % Assume always in auto mode
                for k = 1:length(sensor(1).Data)
                    sensor(i).Data{k} = ones(size(sensor(1).Data{k},1),1);
                    sensor(i).Quality{k} = goodQualityVal*ones(size(sensor(1).Quality{k},1),1);
                end
            end
        end
        
        rangePV = [pvGEDLow pvGEDHigh];
        diffPV = rangePV(2) - rangePV(1);
        if isnan(diffPV)
            rangePV = [pvLow pvHigh];
            diffPV = rangePV(2) - rangePV(1);
        end
        if isnan(diffPV)
            rangePV = [pvTrendLow pvTrendHigh];
            diffPV = rangePV(2) - rangePV(1);
        end
        if isnan(diffPV) && isempty(errorMessage)
            errorMessage = MException([executingMfilename 'NoLimitsForPVSensors'],...
                'Insufficient valid sensor data for analysis: PV limits');
            errorCode = cce.CalculationErrorState.NoData;
            throw(errorMessage)
        end
        
        % Convert ctrlErrorThreshold from % to actual
        normCtrlErrorThreshold = threshold/100*diffPV;
        plotTimespan = 1;
        for i = 1:length(sensor)
            if any(cellfun(@isempty,{sensor(i)}))
                plotTimespan = 0;
            elseif any(cellfun(@isempty,{sensor(i).Data}))
                plotTimespan = 0;
            else
                if any(cellfun(@isempty,{sensor(i).Data}))
                    plotTimespan = 0;
                end
            end
        end
        
        if all(plotTimespan==0) && isempty(errorMessage)
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'],...
                'Insufficient valid sensor data for analysis');
            errorCode = cce.CalculationErrorState.NoData;
            throw(errorMessage)
        end
        
        % Ignore data validation
        for i = 1:length(sensor)
            if plotTimespan == 1
                timespanData.plotCntrlData{1}(:,i) = sensor(i).Data{1};
                timespanData.plotQuality{1}(:,i) = sensor(i).Quality{1};
                timespanData.timeStamps = sensor(1).TimeStamp{1};
                timespanData.length = sensor(1).Length(1);
                timespanData.timeStep = sensor(1).TimeStep(1);
            end
        end
        
        % Current data used for controller quality
        timespanDataSample = timespanData;
        timespanDataSample.plotCntrlData{1}(1,:) = timespanDataSample.plotCntrlData{1}(end,:);
        timespanDataSample.plotQuality{1}(1,:) = timespanDataSample.plotQuality{1}(end,:);
        timespanDataSample.timeStamps(1,:) = timespanDataSample.timeStamps(end,:);
        timespanDataSample.plotCntrlData{1}(2:end,:) = [];
        timespanDataSample.plotQuality{1}(2:end,:) = [];
        timespanDataSample.timeStamps(2:end,:) = [];

        k = 1;
        if plotTimespan == 1
            controllerQuality = getControllerQuality(timespanDataSample, goodQualityVal,...
                mappedGoodQualityVal,notRunningQualityVal,...
                controllerConstraint,normCtrlErrorThreshold,k);
        end
        
        controllerQuality = controllerQuality{:};
        % Historical data used for root cause
        % Find sensor(3) high/low values
        if sensorsInd(3) ~= 0
            rangeMV = [mvGEDLow mvGEDHigh];
            diffMV = rangeMV(2) - rangeMV(1);
            if isnan(diffMV)
                rangeMV = [mvLow mvHigh];
                diffMV = rangeMV(2) - rangeMV(1);
            end
            if isnan(diffMV)
                rangeMV = [mvTrendLow mvTrendHigh];
                diffMV = rangeMV(2) - rangeMV(1);
            end
            if isnan(diffMV)
                rangeMV = [0 100];
            end
        else
            rangeMV = [0 100];
        end
        
        timespanData.plotCntrlData{1}(:,5) = timespanData.plotCntrlData{1}(:,2)...
            - timespanData.plotCntrlData{1}(:,1);
        idx = length(timespanData.plotCntrlData{1}(:,5));
        timespanData.cntrlQuality{1}(idx) = controllerQuality;
        
        if plotTimespan == 1
            rootCause = getRootCause(timespanData, rangeMV,k);
        end
        
        rootCause = rootCause{1,1}(end);
        outputs.ControllerQuality = controllerQuality;
        outputs.RootCause = rootCause;
        outputs.Timestamp = timespanDataSample.timeStamps(1,:);
        log.logInfo('[%d, %d]', [controllerQuality, rootCause]);
        
    catch errorMessage
        outputs.ControllerQuality = [];
        outputs.RootCause = [];
        outputs.Timestamp = [];
        msg = [errorMessage.stack(1).name, ' Line ',...
            num2str(errorMessage.stack(1).line), '. ', errorMessage.message];
        log.logError(msg);
        if errorCode == cce.CalculationErrorState.Good || isempty(errorCode)
            errorCode = cce.CalculationErrorState.CalcFailed;
        end    
    end
    errorCode = uint32(errorCode);
end