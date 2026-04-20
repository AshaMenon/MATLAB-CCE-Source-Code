function timespanData = originalControllerAnalysis(description, varargin)
    %ORIGINALCONTROLLERANALYSIS Part of the controllerPlotFcn used to create
    %test data
       %% Check inputs
    executingMfilename = ['ap:' mfilename ':'];
    errorMessage = [];
    try
        parser = inputParser;
        parser.addRequired('description',@ischar)
        parser.addParamValue('SensorDataPV',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('SensorDataSP',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('SensorDataMV',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('SensorDataAutoman',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('TuningParameterP',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('TuningParameterI',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('TuningParameterD',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('controllerConstraint','none',@ischar)
        parser.addParamValue('threshold',[],@isnumeric)
        parser.addParamValue('tintegral',[],@isnumeric)
        parser.addParamValue('unitNameInTree','',@ischar)
        parser.addParamValue('tagNames','',@(a)ischar(a)||iscell(a))
        parser.addParamValue('report','full',@ischar)
        parser.addParamValue('link',struct.empty,@isstruct);
        parser.addParamValue('OPMCondition',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        parser.addParamValue('OPMExclude',struct.empty,@(a)isa(a,'OPMDataCollections.AnalysisInputCollection')||isa(a,'struct'))
        
        % parser input
        parser.parse(description,varargin{:})
    catch exception
        % Compile input array
        errorMessage = ['Error during analysis function parameter parsing: ' exception.message(1:end-1) ' for function with inputs:'];
        inputArray = [description; varargin'];
        for i = 1:length(inputArray)
            if ischar(inputArray{i})
                errorMessage = [errorMessage ' ' inputArray{i} ';'];
            elseif isnumeric(inputArray{i})
                errorMessage = [errorMessage ' ' num2str(inputArray{i}) ';'];
            elseif isstruct(inputArray{i})
                try errorMessage = [errorMessage ' ' num2str(inputArray{i}.Context.NameInTree) ';']; catch, end
            end
        end
        errorMessage(end) = [];
        errorMessage = MException([executingMfilename 'paramerterParsingError'],errorMessage);
    end
    %% Perform analysis
%try
    tintegral = parser.Results.tintegral;
    threshold = parser.Results.threshold;

    % Prepare the output
    result  = AnalysisResult(sprintf('Control plot (for combined data): %s',description)); % Create container for analysis results
    
    % sensors are the 4 sensors from varargin
    sensors = [parser.Results.SensorDataPV parser.Results.SensorDataSP parser.Results.SensorDataMV parser.Results.SensorDataAutoman];
    %checks if empty
    sensorsInd = [~isempty(parser.Results.SensorDataPV) ~isempty(parser.Results.SensorDataSP) ~isempty(parser.Results.SensorDataMV) ~isempty(parser.Results.SensorDataAutoman)];
    % Could this be a parameter?
    tuning = [parser.Results.TuningParameterP parser.Results.TuningParameterI parser.Results.TuningParameterD];
    %checks if empty
    tuningInd = [~isempty(parser.Results.TuningParameterP) ~isempty(parser.Results.TuningParameterI) ~isempty(parser.Results.TuningParameterD)];
    % Dont think need
    unitNameInTree = parser.Results.unitNameInTree;
    % Dont think we need
    tagNames = parser.Results.tagNames;
    % Parameter?
    controllerConstraint = parser.Results.controllerConstraint;
    % Dont think we need
    reportType = parser.Results.report;
    % Dont think we need
    link = parser.Results.link;
    
    % Do we need this?
    opmCondition = parser.Results.OPMCondition;
    opmExclude = parser.Results.OPMExclude;
    condition = [];
%     if ~isempty(opmCondition) && ~isempty(opmCondition.Context) && ~isempty(cat(1,opmCondition.Data.Value))
%         condition.name = opmCondition.Context.NameInTree;
%         condition.ts = cat(1,opmCondition.Data.TimeStamp);
%         condition.data = cat(1,opmCondition.Data.Value);
%         condition.excludeName = [];
%         if ~isempty(opmExclude) && ~isempty(opmExclude.Context) && ~isempty(cat(1,opmExclude.Data.Value))
%             condition.excludeName = opmExclude.Context.NameInTree;
%             condition.excludeData = cat(1,opmExclude.Data.Value);
%             condition.excludeData(isnan(condition.excludeData)) = 1; % if excludeData = NaN, then set to 1 (set to exclude from dataset)
%             condition.excludeData = logical(condition.excludeData);
%             % Mark condition data to be excluded as NaN
%             condition.data(condition.excludeData) = NaN;
%             % Mark sensor data & quality to be excluded as NaN
%             for j = 1:length(sensors)
%                 for i = 1:length(sensors(j).Data)
%                     dataToExclude = opmExclude.Data(i).Value;
%                     dataToExclude(isnan(dataToExclude)) = 1; % if excludeData = NaN, then set to 1 (set to exclude from dataset)
%                     sensors(j).Data(i).Value(logical(dataToExclude)) = NaN;
%                     sensors(j).Data(i).Quality(logical(dataToExclude)) = ap.DataQuality.opmqualityval('missing data');
%                 end
%             end
%             for j = 1:length(tuning)
%                 for i = 1:length(tuning(j).Data)
%                     dataToExclude = opmExclude.Data(i).Value;
%                     dataToExclude(isnan(dataToExclude)) = 1; % if excludeData = NaN, then set to 1 (set to exclude from dataset)
%                     tuning(j).Data(i).Value(logical(dataToExclude)) = NaN;
%                     tuning(j).Data(i).Quality(logical(dataToExclude)) = ap.DataQuality.opmqualityval('missing data');
%                 end
%             end
%         end
%         % Find unique conditions
%         condition.unique = unique(condition.data(~isnan(condition.data)));
%         % Find start/end indices for condition blocks
%         for i = 1:length(condition.unique)
%             condition.legendEntries{i} = ['Class ' num2str(condition.unique(i))];
%             condition.ind(i).data = condition.data==condition.unique(i);
%             found = false;
%             condition.ind(i).start = [];
%             condition.ind(i).end = [];
%             indStart = find(condition.ind(i).data==1);
%             indEnd = find(condition.ind(i).data==0);
%             while ~found
%                 condition.ind(i).start(end+1,1) = indStart(1); % I know this class exist for at least a single data point
%                 indEnd(indEnd <= condition.ind(i).start(end,1)) = []; % This class has a finish in this data set
%                 if isempty(indEnd)
%                     condition.ind(i).end(end+1,1) = indStart(end); % Once class started, all data points in data set is for this class
%                     found = true;
%                 else
%                     condition.ind(i).end(end+1,1) = indEnd(1)-1;
%                     indStart(indStart <= condition.ind(i).end(end,1)) = []; % Remove these starts as we have found the stop
%                     if isempty(indStart), found = true; end
%                 end
%             end
%         end
%     end
    
    sensorData = cell(1,length(sensors));
    count = 1;
    for k = 1:length(sensorsInd)
        if sensorsInd(k)~=0
            sensorData{k} = sensors(count).Data;
            count = count + 1;
        else
            sensorData{k} = [];
        end
    end

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

    if isempty(condition)
        numTS = length(sensors(1).Data);
    else
        numTS = length(condition.unique);
    end

    % If no controller integral time specified
    if isempty(tintegral), t_i = []; else t_i = tintegral; end
    % If no control error specified
    if isempty(threshold), ctrlErrorThreshold = []; else ctrlErrorThreshold = threshold; end

    % Define constants
    if isempty(t_i)
        if strcmpi(sensors(1).Context.Type,'APCLevelTransmitter'), t_i = 150; % controller integral time [seconds]
        elseif strcmpi(sensors(1).Context.Type,'APCFlowTransmitter'), t_i = 75; % controller integral time [seconds]
        else t_i = 300;
        end
    end
    if isempty(ctrlErrorThreshold)
        if strcmpi(sensors(1).Context.Type,'APCLevelTransmitter'), ctrlErrorThreshold = 4; % controller error %
        elseif strcmpi(sensors(1).Context.Type,'APCFlowTransmitter'), ctrlErrorThreshold = 2; % controller error %
        else ctrlErrorThreshold = 8;
        end
    end

    % Check if critical sensors has data!
    emptyTimespanIndex = [cellfun(@isempty,{sensorData{1}.Value}) cellfun(@isempty,{sensorData{2}.Value})];

    % Check if critical sensors contrains data
    if any(emptyTimespanIndex) & isempty(errorMessage)
        if sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(1) == 1
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV');
        elseif sum(emptyTimespanIndex) == 1 && emptyTimespanIndex(2) == 1
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: SP');
        else
            errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis: PV & SP');
        end
    end

    % Get the data
    % TODO: If sufficient time preallocate memory for a structure.
    % Could preallocate by using something like:
    % cellfun(@(x) cellfun(@length, {x.TimeStamp}), sensorData) with DEAL
%     goodQualityVal      = DataQuality.opmqualityval('good');
%     notRunningQualityVal= DataQuality.opmqualityval('not running');
%     mappedGoodQualityVal = DataQuality.opmqualityval('mapped good'); % Identify the not running values
    goodQualityVal      = 0;
    notRunningQualityVal= 2;
    mappedGoodQualityVal = 65534;
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
    end

    for i = 1:length(tuningInd)
        if tuningInd(i)~=0 && ~any([tuningData{i}.IsEmpty])
            tuningSensor(i).Data = {tuningData{i}.Value}; %#ok
            tuningSensor(i).Quality = {tuningData{i}.Quality}; %#ok
            tuningSensor(i).TimeStamp = {tuningData{i}.TimeStamp}; %#ok
        else
            % Assume output NaN's
            for k = 1:length(sensor(1).Data)
                tuningSensor(i).Data{k} = NaN(size(sensor(1).Data{k},1),1); 
                tuningSensor(i).Quality{k} = goodQualityVal*ones(size(sensor(1).Quality{k},1),1); 
            end
            tuningSensor(i).TimeStamp = {sensorData{1}.TimeStamp}; %#ok
        end
    end

    rangePV = [sensors(1).Context.Parameters.GEDLow sensors(1).Context.Parameters.GEDHigh];
    diffPV = rangePV(2) - rangePV(1);
    if isnan(diffPV)
        rangePV = [sensors(1).Context.Parameters.Low sensors(1).Context.Parameters.High];
        diffPV = rangePV(2) - rangePV(1);
    end
    if isnan(diffPV)
        rangePV = [sensors(1).Context.Parameters.TrendLow sensors(1).Context.Parameters.TrendHigh];
        diffPV = rangePV(2) - rangePV(1);
    end
    if isnan(diffPV) & isempty(errorMessage)
        errorMessage = MException([executingMfilename 'NoLimitsForPVSensors'], 'Insufficient valid sensor data for analysis: PV limits');
    end
    % Convert ctrlErrorThreshold from % to actual
    normCtrlErrorThreshold = ctrlErrorThreshold/100*diffPV;

    % Prepare the data for plotting
    % Check if reference & current data available
    if isempty(condition)
        plotTimespan = ones(1,numTS);
    else
         plotTimespan = ones(1,numTS);
    end
    for i = 1:length(sensor)
        for k = 1:numTS
            if any(cellfun(@isempty,{sensor(i)}))
                plotTimespan(k) = 0;
            elseif any(cellfun(@isempty,{sensor(i).Data}))
                plotTimespan(k) = 0;
            elseif isempty(condition)
                if any(cellfun(@isempty,{sensor(i).Data(k)}))
                    plotTimespan(k) = 0;
                end
            elseif ~isempty(condition)
                tmpSensorData = cat(1,sensor(i).Data{:});
                if isempty(tmpSensorData(condition.ind(k).data))
                    plotTimespan(k) = 0;
                end
            end
        end
    end
    
    if all(plotTimespan==0) & isempty(errorMessage)
        errorMessage = MException([executingMfilename 'NoDataForCriticalSensors'], 'Insufficient valid sensor data for analysis');
    end

    % Ignore data validation
    for k = 1:numTS
        for i = 1:length(sensor)
            if plotTimespan(k) == 1
                if isempty(condition)
                    timespanData.plotCntrlData{k}(:,i) = [sensor(i).Data{k}];
                    timespanData.plotQuality{k}(:,i) = [sensor(i).Quality{k}];
                    timespanData.timeStamps{k} = sensor(1).TimeStamp{k};
                    timespanData.length{k} = sensor(1).Length{k};
                    timespanData.timeStep{k} = sensor(1).TimeStep{k};
                else
                    tmpSensorData = cat(1,sensor(i).Data{:});
                    timespanData.plotCntrlData{k}(:,i) = tmpSensorData(condition.ind(k).data);
                    tmpSensorData = cat(1,sensor(i).Quality{:});
                    timespanData.plotQuality{k}(:,i) = tmpSensorData(condition.ind(k).data);
                    tmpSensorData = cat(1,sensor(1).TimeStamp{:});
                    timespanData.timeStamps{k} = tmpSensorData(condition.ind(k).data);
                    timespanData.length{k} = length(timespanData.timeStamps{k});
                    timespanData.timeStep{k} = sensor(1).TimeStep{1};
                end
            end
        end
    end

    for k = 1:numTS
        for i = 1:length(tuningSensor)
            if plotTimespan(k) == 1
                if isempty(condition)
                    timespanTuningData.plotCntrlData{k}(:,i) = [tuningSensor(i).Data{k}];
                    timespanTuningData.plotQuality{k}(:,i) = [tuningSensor(i).Quality{k}];
                    timespanTuningData.timeStamps{k} = tuningSensor(1).TimeStamp{k};
                else
                    tmpSensorData = cat(1,tuningSensor(i).Data{:});
                    timespanTuningData.plotCntrlData{k}(:,i) = tmpSensorData(condition.ind(k).data);
                    tmpSensorData = cat(1,tuningSensor(i).Quality{:});
                    timespanTuningData.plotQuality{k}(:,i) = tmpSensorData(condition.ind(k).data);
                    tmpSensorData = cat(1,tuningSensor(1).TimeStamp{:});
                    timespanTuningData.timeStamps{k} = tmpSensorData(condition.ind(k).data);
                end
            end
        end
    end

    % Calculate control errors
    timespanData.badData = repmat({NaN},1,numTS);
    timespanData.manualData = repmat({NaN},1,numTS);
    timespanData.autoData = repmat({NaN},1,numTS);
    timespanData.poorCntrl = repmat({NaN},1,numTS);
    timespanData.upperSat = repmat({NaN},1,numTS);
    timespanData.lowerSat = repmat({NaN},1,numTS);
    timespanData.oscInd = repmat({NaN},1,numTS);
    timespanData.opStability = repmat({NaN},1,numTS);
    timespanData.spStability = repmat({NaN},1,numTS);
    stability = cell(1,numTS);

    cntrlQualityStrings = {'Instrument Fault' 'Manual' 'Internal Error' 'Unhealthy' 'Healthy'};
    rootCauseStrings = {'Saturation' 'Disturbance/Slow Control' 'Disturbance/Fast Inner Loop' 'Valve Stiction/Pump Problem' 'Cause Unknown'};
    for k = 1:numTS
        if plotTimespan(k) == 1
            % Assign good data as large number
            timespanData.plotQuality{k}(timespanData.plotQuality{k}==goodQualityVal) = mappedGoodQualityVal;
            % Identify minimum quality value of all sensors
            timespanData.quality{k} = nanmin(timespanData.plotQuality{k},[],2);
            % Reset good quality marker
            timespanData.quality{k}(timespanData.quality{k}==mappedGoodQualityVal) = goodQualityVal;
            % Identify where insturment data good & running & controller in auto
            if size(timespanData.plotCntrlData{k},2) == 4
                timespanData.inCtrlData{k} = (timespanData.quality{k}==goodQualityVal & timespanData.plotCntrlData{k}(:,4)==1);
            else
                timespanData.inCtrlData{k} = (timespanData.quality{k}==goodQualityVal);
            end

            % Assign default "(0)" to all controller quality
            timespanData.cntrlQuality{k} = zeros(size(timespanData.plotQuality{k},1),1);
            % Assign "Healthy (5)" to all not running data
            timespanData.cntrlQuality{k}(any(timespanData.plotQuality{k}==notRunningQualityVal,2)) = 5;
            % Assign "Instrument fault (1)" to faulty instrument data
            timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & timespanData.quality{k}~=goodQualityVal) = 1;
            % Assign "Manual (2)" to controllers in manual data
            if size(timespanData.plotCntrlData{k},2) == 4
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & timespanData.plotCntrlData{k}(:,4)==0) = 2;
            end
            % Calculate SP error - column 5
            timespanData.plotCntrlData{k}(:,5) = timespanData.plotCntrlData{k}(:,2) - timespanData.plotCntrlData{k}(:,1);
    %         % Calculate normalised SP error
    %         timespanData.normPlotData{k} = (timespanData.plotCntrlData{k}(:,5) - rangePV(1))/(diffPV);
            % Assign "Unhealthy (4)" to controllers in exceeding control error threshold
            if strcmpi(controllerConstraint,'upper')
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & (timespanData.plotCntrlData{k}(:,5))<(-normCtrlErrorThreshold)) = 4;
            elseif strcmpi(controllerConstraint,'lower')
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & (timespanData.plotCntrlData{k}(:,5))>normCtrlErrorThreshold) = 4;
            else
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & abs(timespanData.plotCntrlData{k}(:,5))>normCtrlErrorThreshold) = 4;
            end
            % Assign "Healthy (5)" to controllers within control error threshold
            if strcmpi(controllerConstraint,'upper')
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & (timespanData.plotCntrlData{k}(:,5))>=(-normCtrlErrorThreshold)) = 5;
            elseif strcmpi(controllerConstraint,'lower')
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & (timespanData.plotCntrlData{k}(:,5))<=normCtrlErrorThreshold) = 5;
            else
                timespanData.cntrlQuality{k}(timespanData.cntrlQuality{k}==0 & abs(timespanData.plotCntrlData{k}(:,5))<=normCtrlErrorThreshold) = 5;
            end

            % Find sensor(3) high/low values
            if sensorsInd(3) ~= 0
                rangeMV = [sensors(3).Context.Parameters.GEDLow sensors(3).Context.Parameters.GEDHigh];
                diffMV = rangeMV(2) - rangeMV(1);
                if isnan(diffMV)
                    rangeMV = [sensors(3).Context.Parameters.Low sensors(3).Context.Parameters.High];
                    diffMV = rangeMV(2) - rangeMV(1);
                end
                if isnan(diffMV)
                    rangeMV = [sensors(3).Context.Parameters.TrendLow sensors(3).Context.Parameters.TrendHigh];
                    diffMV = rangeMV(2) - rangeMV(1);
                end
                if isnan(diffMV)
                    rangeMV = [0 100];
                end
            else
                rangeMV = [0 100];
            end
            % Calculate MV deadband
            mvDeadBand = [rangeMV(1)+2/100*diff(rangeMV) rangeMV(2)-2/100*diff(rangeMV)];
            % Assign default "(0)" to all controller rootcause
            timespanData.rootCause{k} = zeros(size(timespanData.plotQuality{k},1),1);
            % Assign "Cause unknown (5)" to all "Unhealty (4)" quality within first moving window
            timespanData.rootCause{k}(timespanData.cntrlQuality{k}(1:60*60/timespanData.timeStep{k}-1)==4) = 5;
            % Calculate root cause over hourly moving window
            for i = 60*60/timespanData.timeStep{k}:length(timespanData.plotCntrlData{k})
                % Only determine root cause for "Unhealty (4)" controller quality
                if timespanData.cntrlQuality{k}(i) == 4
                    movingWindow = (i-60*60/timespanData.timeStep{k}+1:i);
                    if sum(timespanData.plotCntrlData{k}(movingWindow,3) < mvDeadBand(1))/(60*60/timespanData.timeStep{k})*100 > 50 % more than 10% of data saturated at low limit
                        % Assign "Saturation (1)" to controller rootcause
                        timespanData.rootCause{k}(i) = 1;
                    elseif sum(timespanData.plotCntrlData{k}(movingWindow,3) > mvDeadBand(2))/(60*60/timespanData.timeStep{k})*100 > 50 % more than 10% of data saturated at high limit
                        % Assign "Saturation (1)" to controller rootcause
                        timespanData.rootCause{k}(i) = 1;
                    else
                        % Calculate filtered control error
%                         if ceil(30/timespanData.timeStep{k}) < 2
%                             timespanData.filtplotData{k} = timespanData.plotCntrlData{k}(movingWindow,5);
%                         else
%                             timespanData.filtplotData{k} = filtfilt(ones(ceil(30/timespanData.timeStep{k}),1)/ceil(30/timespanData.timeStep{k}),1,timespanData.plotCntrlData{k}(movingWindow,5));
%                         end
                        timespanData.filtplotData{k} = timespanData.plotCntrlData{k}(movingWindow,5);
                        % Fill missing data with previous value
                        timespanData.filtplotData{k} = fillmissing(timespanData.filtplotData{k},'previous');
                        if ceil(30/timespanData.timeStep{k}) >= 2
                            timespanData.filtplotData{k} = filtfilt(ones(ceil(30/timespanData.timeStep{k}),1)/ceil(30/timespanData.timeStep{k}),1,timespanData.plotCntrlData{k}(movingWindow,5));
                        end
                        % Check for oscillation
%                         autoCorrelation = acf(timespanData.filtplotData{k},60*60/timespanData.timeStep{k});
%                         autoCorrelation(1:60*60/timespanData.timeStep{k}+1) = [];
                        autoCorrelation = [0.447986145088299;-1.32074885771385;-Inf;0];
                        normAutoCorrelation = autoCorrelation;
                        normAutoCorrelation(autoCorrelation>=0) = 1;
                        normAutoCorrelation(autoCorrelation<0) = 0;
                        pos = find(diff(normAutoCorrelation)==1);
                        neg = find(diff(normAutoCorrelation)==-1);
                        % Find half periods 2-11
                        Tp = [];
                        for j = 1:min([5 length(pos) length(neg)-1])
                            Tp(end+1) = length(neg(j)+1:pos(j));
                            Tp(end+1) = length(pos(j)+1:neg(j+1));
                        end
                        if length(Tp) < 4
                            % Assign "Cause unknown (5)" to controller rootcause
                            timespanData.rootCause{k}(i) = 5;
                        elseif 1/3*mean(Tp)/std(Tp) <= 1
                            % Assign "External disturbance or slow control (2)" to controller rootcause
                            timespanData.rootCause{k}(i) = 2;
                        else % control loop oscillating, check for stiction
                            MSEtri = [];
                            MSEsin = [];
                            % For each of the oscillations
                            for j = 1:min([5 length(pos) length(neg)-1])
                                % For each of the half periods per oscillation
                                for m = 1:2
                                    if m == 1
                                        halfPeriodData = abs(autoCorrelation(neg(j)+1:pos(j)));
                                    elseif m == 2
                                        halfPeriodData = abs(autoCorrelation(pos(j)+1:neg(j+1)));
                                    end
                                    % For each of the peak locations calculate MSEtri
                                    MSEtri(end+1) = inf;
                                    for n = 2:length(halfPeriodData)-1
                                        % Fit positive y = mx + c; model = [x - x0]\(y - y0);
                                        modelPos = ([1:n]'-1)\(halfPeriodData(1:n)-halfPeriodData(1));
                                        % ypred = polyval([model;y0],xpred - x0);
                                        ypredPos = polyval([modelPos;halfPeriodData(1)],[1:n]' - 1);
                                        % Fit negative y = -mx + c; model = [x - x0]\(y - y0);
                                        modelNeg = ([n:length(halfPeriodData)]'-length(halfPeriodData))\(halfPeriodData(n:end)-halfPeriodData(end));
                                        % ypred = polyval([model;y0],xpred - x0);
                                        ypredNeg = polyval([modelNeg;halfPeriodData(end)],[n:length(halfPeriodData)]' - length(halfPeriodData));
                                        MSE = mean(([halfPeriodData(1:n);halfPeriodData(n:end)]-[ypredPos; ypredNeg]).^2);
                                        if MSEtri(end) > MSE
                                            MSEtri(end) = MSE;
                                        end
                                    end
                                    % For each of the peak locations calculate MSEsin
                                    % Fit y = msin(x); model = sin(x)\y;
                                    model = sin([0:length(halfPeriodData)-1]'/pi)\(halfPeriodData/max(halfPeriodData));
                                    % Evaluate model
                                    ypred = model*sin([0:length(halfPeriodData)-1]'/pi);
                                    MSEsin(end+1) = mean((halfPeriodData-ypred).^2);
                                end
                            end
                            % Calculate stiction index
                            SI = nanmean(MSEsin) / (nanmean(MSEsin) + nanmean(MSEtri));
                            if SI < 0.4
                                % Assign "Inner loop too fast or external disturbance (3)" to controller rootcause
                                timespanData.rootCause{k}(i) = 3;
                            elseif SI > 0.6
                                % Assign "Valve stiction or pump problem (4)" to controller rootcause
                                timespanData.rootCause{k}(i) = 4;
                            else
                                % Assign "Cause unknown (5)" to controller rootcause
                                timespanData.rootCause{k}(i) = 5;
                            end
                        end
                    end
                end
            end
            % Calculate error to export to database
            timespanData.sensorErrorAve{k} = nanmean(timespanData.plotCntrlData{k}(timespanData.inCtrlData{k}==1,5));
            timespanData.sensorErrorStd{k} = nanstd(timespanData.plotCntrlData{k}(timespanData.inCtrlData{k}==1,5));
        end
    end
end

