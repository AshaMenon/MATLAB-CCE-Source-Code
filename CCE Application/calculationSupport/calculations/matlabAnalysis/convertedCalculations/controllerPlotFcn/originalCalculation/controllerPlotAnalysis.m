function [controllerQuality, rootCause] = controllerPlotAnalysis(parameters,...
        sensorDataPV, sensorDataSP, sensorDataMV, sensorDataAutoman)
    
    %Inputs:
    %   sensorData: struct with the following fields:
    %       Values
    %       Timestamps
    %       Quality
    %       TrendHigh
    %       TrendLow
    %       GEDLow
    %       GEDHigh
    %       High
    %       Low
    
    %Parameters:
    %   ControllerConstraint
    %   Threshold: if sensor type = 'APCLevelTransmitter', Threshold = 4
    %   if sensor type = 'APCFlowTransmitter', Threshold = 2, else Threshold = 8
    
    
    % Check inputs
    try
        
        tintegral = parameters.Tintegral;
        threshold = parameters.Threshold;
        tuningParameterP = parameters.TuningParameterP;
        tuningParameterI = parameters.TuningParameterI;
        tuningParameterD = parameters.TuningParameterD;
        controllerConstraint = parameters.ControllerConstraint;
        goodQualityVal = parameters.GoodQualityVal;
        notRunningQualityVal= parameters.NotRunningQualityVal;
        mappedGoodQualityVal = parameters.MappedGoodQualityVal;
        
        inputValidation(sensorDataPV, 'struct');
        inputValidation(sensorDataSP, 'struct');
        inputValidation(tuningParameterP, 'struct');
        inputValidation(tuningParameterI, 'struct');
        inputValidation(tuningParameterD, 'struct');
        inputValidation(sensorDataAutoman, 'struct');
        inputValidation(sensorDataMV, 'struct');
%         inputValidation(sensorQualityPV, 'double');
%         inputValidation(sensorQualitySP, 'double');
%         inputValidation(sensorQualityMV, 'double');
%         inputValidation(sensorQualityAutoman, 'double');
        
        
        
        if ~isnumeric(threshold) || ~isnumeric(tintegral) ||...
                ~ischar(controllerConstraint)
            err = MException('InputValidation:InputTypeNotValid', ...
                'Input type not valid');
            throw(err)
        end
        
        if isempty(threshold)
            threshold = 8;
        end
        
        if isempty(tintegral)
            tintegral = 300;
        end
    catch err
        controllerQuality = [];
        rootCause = [];
        %TO DO: Log Error
    end
    %% Perform analysis
    %try
    
    pvSensor = inputTranslation(sensorDataPV);
    spSensor = inputTranslation(sensorDataSP);
    
    sensorsInd = [~isempty(sensorDataPV) ~isempty(sensorDataSP),...
        ~isempty(sensorDataMV) ~isempty(sensorDataAutoman)];
    
    if sensorsInd(3)
        mvSensor = inputTranslation(sensorDataMV);
    else
        mvSensor = struct.empty(0,0);
    end
    
    if sensorsInd(4)
        automanSensor = inputTranslation(sensorDataAutoman);
    else
        automanSensor = struct.empty(0,0);
    end
    
    sensorData = {pvSensor, spSensor, mvSensor, automanSensor};
    %%
    
    tuning = [tuningParameterP tuningParameterI tuningParameterD];
    %checks if empty
    tuningInd = [~isempty(tuningParameterP) ~isempty(tuningParameterI),...
        ~isempty(tuningParameterD)];
    
    tuningData = cell(1,length(tuning));
    count = 1;
    for k = 1:length(tuningInd)
        if tuningInd(k)~=0
            tuningData{k} = tuning(count).Data;
            count = count + 1;
        else
            tuningData{k} = [];
        end
    end
    
    emptyTimespanIndex = [cellfun(@isempty,{sensorData{1}.Value}) cellfun(@isempty,{sensorData{2}.Value})];
    
    % Check if critical sensors contrains data
    % TODO Handle these errors
    if any(emptyTimespanIndex) && isempty(errorMessage)
        if sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(1) == 1
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV');
        elseif sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(2) == 1
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: SP');
        else
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV & SP');
        end
    end
    
    numOfRows = 60*60/sensorData{1}.TimeStep;
    
    for i = 1:length(sensorsInd)
        if sensorsInd(i)~=0 && ~any([sensorData{i}.IsEmpty])
            sensor(i).Data = {sensorData{i}.Value}; %#ok
            sensor(i).Quality = {sensorData{i}.Quality}; %#ok
            sensor(i).TimeStamp = {sensorData{i}.TimeStamp}; %#ok
            sensor(i).TimeStep = {sensorData{i}.TimeStep}; %#ok
            sensor(i).Label = {sensorData{i}.Label}; %#ok
            sensor(i).Length = {sensorData{i}.Length}; %#ok
            if i == 4 % If auto mode we need to replace missing data with last good value
                for k = 1:length(sensor(i).Data)
                    % Replace missing data with last good value
                    if any(isnan(sensor(i).Data{k}))
                        [sensor(i).Data{k},sensor(i).Quality{k}] = replaceMissingData(sensor(i).Data{k},sensor(i).Quality{k});
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
        % Make sure values are for 1 hour - Root cause is calculated using
        % an hourly window.
        if length(sensor(i).Data{:}) > numOfRows
            sensor(i).Data{1,1}(numOfRows+1:end) = [];
        end
        
        if length(sensor(i).Quality{:}) > numOfRows
            sensor(i).Quality{1,1}(numOfRows+1:end) = [];
        end
        
        if length(sensor(i).TimeStamp{:}) > numOfRows
            sensor(i).TimeStamp{1,1}(numOfRows+1:end) = [];
        end
    end
    
    
    rangePV = [sensorDataPV.GEDLow sensorDataPV.GEDHigh];
    diffPV = rangePV(2) - rangePV(1);
    if isnan(diffPV)
        rangePV = [sensorDataPV.Low sensorDataPV.High];
        diffPV = rangePV(2) - rangePV(1);
    end
    if isnan(diffPV)
        rangePV = [sensorDataPV.TrendLow sensorDataPV.TrendHigh];
        diffPV = rangePV(2) - rangePV(1);
    end
    if isnan(diffPV) && isempty(errorMessage)
        errorMessage = MException([executingMfilename 'NoLimitsForPVSensors'], 'Insufficient valid sensor data for analysis: PV limits');
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
        errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis');
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
    
%     for i = 1:length(tuningSensor)
%         if plotTimespan == 1
%             timespanTuningData.plotCntrlData{1}(:,i) = [tuningSensor(i).Data];
%             timespanTuningData.plotQuality{:,i} = [tuningSensor(i).Quality];
%             timespanTuningData.timeStamps = tuningSensor(1).TimeStamp;
%         end
%     end
    
    
    timespanDataSample = timespanData;
    timespanDataSample.plotCntrlData{1}(2:end,:) = [];
    timespanDataSample.plotQuality{1}(2:end,:) = [];
    timespanDataSample.timeStamps(2:end,:) = [];
    
    k = 1;
    if plotTimespan == 1
        controllerQuality = getControllerQuality(timespanDataSample, goodQualityVal,...
            mappedGoodQualityVal,notRunningQualityVal,...
            controllerConstraint,normCtrlErrorThreshold,k);
    end
    
    previousControllerQuality = ones(length(timespanData.plotCntrlData{1}),1) * 4;
    timespanData.cntrlQuality{1} = [controllerQuality{:};...
        previousControllerQuality];

    % Find sensor(3) high/low values
    if sensorsInd(3) ~= 0
        rangeMV = [sensorDataMV.GEDLow sensorDataMV.GEDHigh];
        diffMV = rangeMV(2) - rangeMV(1);
        if isnan(diffMV)
            rangeMV = [sensorDataMV.Low sensorDataMV.High];
            diffMV = rangeMV(2) - rangeMV(1);
        end
        if isnan(diffMV)
            rangeMV = [sensorDataMV.TrendLow sensorDataMV.TrendHigh];
            diffMV = rangeMV(2) - rangeMV(1);
        end
        if isnan(diffMV)
            rangeMV = [0 100];
        end
    else
        rangeMV = [0 100];
    end
    
    timespanData.plotCntrlData{1}(:,5) = timespanData.plotCntrlData{1}(:,2) - timespanData.plotCntrlData{1}(:,1);
    
    
    if plotTimespan == 1
        rootCause = getRootCause(timespanData, rangeMV,k);
    end
    rootCause = rootCause{1,1}(1);
    
end