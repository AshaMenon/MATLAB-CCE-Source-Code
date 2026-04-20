classdef Coordinator < handle & matlab.mixin.CustomDisplay
    %cce.Coordinator  Coordinator class
    %   The Coordinator class is responsible for the running of calculations in CCE. All Coordinators
    %   for a CCE system are stored in the CCE System Coordinator Database.
    %
    %   You construct Coordinators by creating a new Coordinator Record using Coordinator.createNew, or
    %   by retrieving existing records using Coordinator.fetchFromDb.
    %
    %   Coordinators have the following properties:
    %   Behaviour Properties:
    %       CoordinatorID: Unique ID of the Coordinator
    %       ExecutionMode: Controls how the Coordinator runs the outer loop. [Single, Cyclic, Event, Manual]
    %       ExecutionFrequency: Frequency of execution for Cyclic execution mode
    %       ExecutionOffset: Offset from midnight for calculation execution cycles
    %       Lifetime: Lifetime of the Coordinator in Cyclic or Event mode
    %       CalculationLoad: Number of calculations managed by this Coordinator
    %       MaxCalculationLoad: Maximum allowable number of calculations
    %       managed by this coordinator. If set to 0, uses cce.System value.
    %       CoordinatorState: Coordinator State - NotRunning, Idle, Backfilling, Executing
    %       RequestToDisable: User request to disable a running Coordinator
    %
    %   Coordinator Methods:
    %       setup(): Set up the Coordinator
    %       runMainLoop(): Runs the main monitoring loop, waiting for triggers to run the calculations
    %       executeCalcs(outputTime): Executes the calculations for the required outputTime
    %       shutdown(): Execute shutdown tasks
    %
    %   See also: Coordinator.fetchFromDb, Coordinator.createNew
    
    properties (Dependent, SetAccess = private) % These properties are implemented in the DbRecord
        % Unique ID of the Coordinator
        CoordinatorID (1,1) int32;
    end
    properties (Dependent) % These properties are implemented in the DbRecord
        % Controls how the Coordinator runs the outer loop. [Single, Cyclic, Event, Manual]
        ExecutionMode (1,1) cce.CoordinatorExecutionMode
        % Frequency of execution for Cyclic execution mode
        ExecutionFrequency (1,1) duration
        % Offset from midnight for calculation execution cycles
        ExecutionOffset (1,1) duration
        % Lifetime of the Coordinator in Cyclic or Event mode
        Lifetime (1,1) duration
        % Number of calculations managed by this Coordinator
        CalculationLoad (1,1) uint32
        % Maximum calculation load
        MaxCalculationLoad (1,1) uint32
        % Coordinator State - NotRunning, Idle, Backfilling, Executing
        CoordinatorState (1,1) cce.CoordinatorState
        % Set by PI user to request disable of the Coordinator
        RequestToDisable (1,1) logical
        % Set to true to commit changes to the database immediately on set.
        AutoCommit (1,1) logical
        % When set to true, all system disabled calcs in coordinator set to
        % idle
        ReenableSystemDisabledCalcs (1, 1) logical
        %Selected by user to set log level specific to a coordinator
        LogLevel (1, 1) LogMessageLevel
        %Selected by user to specify a coordinator specific log name
        LogName (1, 1) string
        %Selected by user to specify how long to wait for a calculation
        %retry after network error
        RetryFrequency (1, 1) uint32
        SkipBackfill (1, 1) logical
        ElementName string
    end
    
    properties (Access = private)
        % Implementation of the above properties
        DbRecord (1,1);
    end
    
    properties (SetAccess = private)
        % List of calculations managed by this Coordinator
        Calculations (1,:) cce.Calculation = cce.Calculation.empty;
    end
    
    methods (Access = private) % Constructor - Private because of dependency on DbRecord
        function obj = Coordinator(dbInterface, systemLogger)
            %Coordinator  Construct a Coordinator - Private method
            %   You cannot construct Coordinators directly. Instead, use one of the static methods:
            %       Coordinator.fetchFromDb
            %       Coordinator.createNew
            %
            %   See also: Coordinator.createNew, Coordinator.fetchFromDb
            
            % Since properties are all stored in the DbRecord, just set that.
            if nargin>0
                for dI = numel(dbInterface):-1:1
                    obj(dI).DbRecord = dbInterface(dI);
                    loadCalculations(obj(dI), systemLogger);
                end
            end
        end
    end
    
    methods % Property setters and getters - defer everything to DbRecord class
        function id = get.CoordinatorID(obj)
            id = obj.DbRecord.getField("CoordinatorID");
        end
        % Cannot set the CoordinatorID property.
        function mode = get.ExecutionMode(obj)
            mode = obj.DbRecord.getField("ExecutionMode");
        end
        function set.ExecutionMode(obj, val)
            obj.DbRecord.setField("ExecutionMode", val);
        end
        function frequency = get.ExecutionFrequency(obj)
            frequency = bestDurationFormat(obj.DbRecord.getField("ExecutionFrequency"));
        end
        function set.ExecutionFrequency(obj, val)
            obj.DbRecord.setField("ExecutionFrequency", val);
        end
        function offset = get.ExecutionOffset(obj)
            offset = bestDurationFormat(obj.DbRecord.getField("ExecutionOffset"));
        end
        function set.ExecutionOffset(obj, val)
            obj.DbRecord.setField("ExecutionOffset", val);
        end
        function lifetime = get.Lifetime(obj)
            lifetime = bestDurationFormat(obj.DbRecord.getField("Lifetime"));
        end
        function set.Lifetime(obj, val)
            obj.DbRecord.setField("Lifetime", val);
        end
        function calcLoad = get.CalculationLoad(obj)
            calcLoad = obj.DbRecord.getField("CalculationLoad");
        end
        function set.CalculationLoad(obj, val)
            obj.DbRecord.setField("CalculationLoad", val);
        end
        function maxCalcLoad = get.MaxCalculationLoad(obj)
            maxCalcLoad = obj.DbRecord.getField("MaxCalculationLoad");
        end
        function set.MaxCalculationLoad(obj, val)
            obj.DbRecord.setField("MaxCalculationLoad", val);
        end
        function state = get.CoordinatorState(obj)
            state = obj.DbRecord.getField("CoordinatorState");
        end
        function set.CoordinatorState(obj, val)
            obj.DbRecord.setField("CoordinatorState", val);
        end
        function state = get.RequestToDisable(obj)
            state = obj.DbRecord.getField("RequestToDisable");
        end
        function set.RequestToDisable(obj, val)
            arguments
                obj cce.Coordinator
                val (1,1) logical
            end
            obj.DbRecord.setField("RequestToDisable", val);
        end
        function state = get.ReenableSystemDisabledCalcs(obj)
            state = obj.DbRecord.getField("ReenableSystemDisabledCalcs");
        end
        function set.ReenableSystemDisabledCalcs(obj, val)
            arguments
                obj cce.Coordinator
                val (1,1) logical
            end
            obj.DbRecord.setField("ReenableSystemDisabledCalcs", val);
        end
        function logLevel = get.LogLevel(obj)
            logLevel = obj.DbRecord.getField("LogLevel");
        end
        function logName = get.LogName(obj)
            logName = obj.DbRecord.getField("LogName");
        end
        function tf = get.AutoCommit(obj)
            tf = obj.DbRecord.AutoCommit;
        end
        function set.AutoCommit(obj, val)
            obj.DbRecord.AutoCommit = val;
        end
        function retryFrequency = get.RetryFrequency(obj)
            retryFrequency = obj.DbRecord.getField("RetryFrequency");
        end

        function skipBackfill = get.SkipBackfill(obj)
            skipBackfill = obj.DbRecord.getField("SkipBackfill");
        end
        function set.SkipBackfill(obj, val)
            obj.DbRecord.SkipBackfill = val;
        end

        function elementName = get.ElementName(obj)
            elementName = obj.DbRecord.getField("ElementName");
        end
    end
    methods % Database handlers
        function commit(obj)
            obj.DbRecord.commit();
        end
        
        function refreshAttributes(obj)
            for oI = 1:numel(obj)
                obj(oI).DbRecord.readRecord();
            end
        end
    end
    methods
        function loadCalculations(obj, systemLogger)
            % Load Calculations from the Calculation database
            obj.Calculations = cce.Calculation.fetchFromDb(obj.CoordinatorID, "Logger", systemLogger);
        end
    end
    methods % Data converters - mainly for debugging
        function tbl = table(obj)
            %table  Convert Coordinator properties to a table
            objCount = numel(obj);
            execFreqStr = strings(objCount,1);
            for cI = 1:objCount
                if ismember(obj(cI).ExecutionMode, ["Cyclic", "Single"])
                    if seconds(obj(cI).ExecutionOffset) > 0
                        execFreqStr(cI) = sprintf("%s + n(%s)", string(obj(cI).ExecutionFrequency), ...
                            string(obj(cI).ExecutionOffset));
                    else
                        execFreqStr(cI) = string(obj(cI).ExecutionFrequency);
                    end
                else
                    execFreqStr(cI) = "n/a";
                end
            end
            tbl = table([obj.CoordinatorID]', [obj.ExecutionMode]', execFreqStr, ...
                bestDurationFormat([obj.Lifetime]'), [obj.CalculationLoad]', [obj.CoordinatorState]', ...
                'VariableNames', ["ID", "Mode", "Execution Frequency", ...
                "Lifetime", "Load", "State"]);
        end
    end
    methods (Access = protected) % Display methods
        function displayEmptyObject(obj)
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            fprintf('0x0 %s\n', objName);
        end
        function displayNonScalarObject(obj)
            %displayNonScalarObject  Show a table of Coordinator properties
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj) ;
            fprintf('%s %s array:\n', dimStr, objName);
            displayTable = internal.DispTable;
            displayTable.Indent = 4;
            displayTable.ColumnSeparator = '  ';
            displayTable.addColumn('CoordinatorID', 'center');
            displayTable.addColumn('ExecutionMode');
            displayTable.addColumn('Frequency');
            displayTable.addColumn('Lifetime');
            displayTable.addColumn('State');
            displayTable.addColumn('Load');
            for k = 1:numel(obj)
                if (obj(k).ExecutionMode == cce.CoordinatorExecutionMode.Cyclic)
                    if (seconds(obj(k).ExecutionOffset) == 0)
                        execString = string(obj(k).ExecutionFrequency);
                    else
                        execString = string(obj(k).ExecutionOffset) + "(+" + ...
                            string(obj(k).ExecutionFrequency) + ")";
                    end
                else
                    execString = "n/a";
                end
                displayTable.addRow(char(string(obj(k).CoordinatorID)), char(string(obj(k).ExecutionMode)), char(execString), ...
                    char(string(bestDurationFormat(obj(k).Lifetime))), char(obj(k).CoordinatorState), char(string(obj(k).CalculationLoad)));
            end
            disp(displayTable);
        end
    end
    methods (Static)
        function obj = createNew(id, nvArgs)
            % Coordinator.createNew Construct a new Coordinator and write to database
            %   CObj = createNew(id) adds a Coordinator to the CCE System Coordinator Database. The ID must be
            %   unique; if the ID already exists, an error is thrown.
            %
            %   CObj = createNew(id, "Name" = Value, ...) allows you to override the default values for a
            %   Coordinator. The following values can be overwritten:
            %       ExecutionMode : Single
            %       ExecutionFrequency : 1 minute
            %       ExecutionOffset : 0 (seconds)
            %       Lifetime : 8 hours
            %       CalcualtionLoad : 0
            %       DatabaseService : The default CCE system Coordinator Database Service
            %       SkipBackfill : false
            %
            %   Coordinators are always created with a state of "NotConfigured".
            %
            %   See also: Coordinator.fetchFromDb, Coordinator.removeFromDb
            arguments
                id (1,1) uint32
                nvArgs.ExecutionMode (1,1) cce.CoordinatorExecutionMode = cce.CoordinatorExecutionMode.Single;
                nvArgs.ExecutionFrequency (1,1) duration = minutes(1);
                nvArgs.ExecutionOffset (1,1) duration = seconds(0);
                nvArgs.Lifetime (1,1) duration = hours(8);
                nvArgs.CalculationLoad (1,1) uint32 = 0;
                nvArgs.DatabaseService (1,1) = cce.System.getCoordinatorDbService;
                nvArgs.SkipBackfill (1,1) logical = false;
            end
            
            try
                dbRecord = nvArgs.DatabaseService.createCoordinator(id, ...
                    nvArgs.ExecutionMode, nvArgs.ExecutionFrequency, nvArgs.ExecutionOffset, ...
                    nvArgs.Lifetime, nvArgs.CalculationLoad, nvArgs.SkipBackfill);
            catch MExc
                throwAsCaller(MExc); %% TODO: More info
            end
            logger = Logger(cce.System.ConfiguratorLogFile, "Configurator", mfilename, cce.System.ConfiguratorLogLevel);
            logger.LogFileMaxSize = cce.System.LogFileMaxSize;
            logger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
            obj = cce.Coordinator(dbRecord, logger);
        end
        function obj = fetchFromDb(id, nvArgs)
            % Coordinator.fetchFromDb  Load Coordinators from database
            %   CObj = Coordinator.fetchFromDb() retrieves all Coordinators in the CCE System Coordinator
            %   Database.
            %
            %   CObj = Coordinator.fetchFromDb(id) retrieves the specific Coordinator ID from the CCE System
            %   Coordinator Database.
            %
            %   CObj = Coordinator.fetchFromDb(id, DatabaseService=DbService) retrieves the Coordinator ID from the Coordinator
            %   Database Service dbService. If id is empty, all Coordinators are retrieved.
            %
            %   See also: Coordinator.createNew, Coordinator.removeFromDb
            arguments
                id uint32 = [];
                nvArgs.DatabaseService (1,1) cce.ICoordinatorDbService = cce.System.getCoordinatorDbService();
                nvArgs.Logger = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel);
            end
            if isempty(id)
                dbRecords = nvArgs.DatabaseService.findAllCoordinators();
            else
                dbRecords = nvArgs.DatabaseService.findCoordinators(id);
            end
            if ~isempty(dbRecords)
                obj = cce.Coordinator(dbRecords, nvArgs.Logger);
            else
                obj = cce.Coordinator.empty();
            end
        end
        function removeFromDb(id, nvArgs)
            % Coordinator.removeFromDb  Remove Coordinator records from the database
            %   CObj = Coordinator.removeFromDb(id) removes the Coordinator record ID from the CCE System
            %       Coordinator database.
            %
            %   CObj = Coordinator.removeFromDb(id, DatabaseService=DbService) removes the Coordinator record ID
            %       from the Coordinator stored in Database Service dbService. If id is empty, all Coordinators
            %       are retrieved.
            %
            %   See also: Coordinator.createNew, Coordinator.fetchFromDb
            arguments
                id uint32 = [];
                nvArgs.DatabaseService (1,1) cce.ICoordinatorDbService = cce.System.getCoordinatorDbService();
            end
            nvArgs.DatabaseService.removeCoordinator(id);
        end
    end
    
    methods
        function tf = isDisabled(obj)
            %isDisabled  True if a Coordinator is Disabled
            %   isDisabled(obj) returns true if the Coordinator object is disabled. A Coordinator is disabled
            %       when the CoordinatorState is in one of [Disabled, ForDeletion].
            tf = ismember([obj.CoordinatorState], [cce.CoordinatorState.Disabled, cce.CoordinatorState.ForDeletion]);
        end
        
        function executeCalculations(obj, outputTime, coordLogger)
            %executeCalculations  Execute CCE Calculations
            %   executeCalculations(CalcObj, OutputTime, coordLogger) executes all of the
            %       calculations in CalcObj, for the output time OutputTime. Internal
            %       messages (not calculation logs) are logged to coordLogger.

            % Get list of all calculations assigned to coordinator
            calculations = [obj.Calculations];

            % Remove disabled calculations from calculation list
            idxEnabledCalculations = cce.isCalculationActive([calculations.CalculationState]);
            calculations(~idxEnabledCalculations) = [];

            % Find the calculations that need to be run at this output time
            idxNextOutputTime = [calculations.NextOutputTime] == outputTime;
            calculations(~idxNextOutputTime) = [];

            % Get all execution indicies of calculations ready to be ran
            execOrders = unique([calculations.ExecutionIndex]);
            
            % Create the clientID using the CoordinatorID and the current time. Mostly guaranteed to be unique.
            clientID = sprintf('coordinator%d-%s', obj.CoordinatorID, char(datetime("now"), "yyyyMMddHHmmss"));
            % Assume that all calculations are using one CalcServer
            % Create CalcServer object - Use default host and port from config file.
            calcServerObj = CalcServer(clientID);            
            
            for executionOrder = execOrders
                % Find the Calculations that are able to run for this execution index and
                % output time

                % Check if the Calculation matches the current execution order
                idxCalcExecution = [calculations.ExecutionIndex] == executionOrder;
                calcsToRun = calculations(idxCalcExecution);
                                
                % For dependent Calculations - check that the Calculation's inputs are
                % available for the current outputTime: the Calculation is ready to run.
                if executionOrder > 1
                    coordLogger.logTrace("Found %d calculations for execution index %d.", ...
                        length(calcsToRun), executionOrder)
                    outputTimeStr = string(outputTime, 'yyyy-MM-dd HH:mm:ss');

                    coordLogger.logDebug("Checking dependent inputs for Calculations running at output time: %s", ...
                        outputTimeStr);

                    dependCalcsReady = true(numel(calcsToRun),1);

                    for calcIdx = 1:length(dependCalcsReady)
                        dependCalcsReady(calcIdx) = calcsToRun(calcIdx).checkInputsReadyToRun(outputTime, coordLogger);
                    end

                    failedReadyCheckCalcs = calcsToRun(~dependCalcsReady);
                    calcsToRun = calcsToRun(dependCalcsReady);

                    failTime = datetime('now');
                    
                    for failedCalc = failedReadyCheckCalcs
                        % For all the calculations that are not ready to run (i.e.
                        % dependent inputs are not available for the outputTime). Write a
                        % debug message to the local logs.
                        
                        calcID = failedCalc.CalculationID;
                        executionFrequency = failedCalc.ExecutionFrequency;
                        calcFailTimeString = string(failTime, 'yyyy-MM-dd HH:mm:ss');
                        
                        coordLogger.logWarning("Calculation ID: %s dependent inputs not ready for output time: %s.", ...
                            failedCalc.RecordPath, outputTimeStr);
                        
                        % Find the previous failed time (if any) for the calculation for
                        % the current output time. i.e. query the local db where the
                        % stored CalculationId = calcID and the calculation output time =
                        % output time and return the latest failed time before the current
                        % failed time
                        firstFailedCheckTime = getCheckFailedTime(calcID, outputTimeStr);
                        
                        if ismissing(firstFailedCheckTime)
                            % Store the first failed check time, the output time, and the
                            % calculation ID to a local db.
                            % Write:
                            % * CalculationID - unique identifier for the calculation
                            % * outputTime - the calculation run output time
                            % * failedTime - the time of the failed check
                            writeDependenciesReadyFailedTime(calcID, outputTimeStr, char(calcFailTimeString), coordLogger);
                        else
                            failedTimeDiff = failTime - firstFailedCheckTime;
                            % Check the current failed time against the last failed time. If
                            % the time between failures is greater than 80% of the Calculation
                            % execution frequency, make sure that the Calculation does not run
                            % - even on the next cycle.
                            % * Set the CalculationState to Disabled
                            % * Write LastError "DependentInputsNotReady"
                            if failedTimeDiff >= 0.8*(executionFrequency)
                                failedCalc.LastError = cce.CalculationErrorState.DependentInputsNotReady;
                            end
                        end
                    end
                end
                
                if ~isempty(calcsToRun)
                    %Get the Calculation Inputs & Parameters and Queue the Calculations on the
                    %Calculation Server
                    coordLogger.logInfo("Running %d Calculations with Execution Index: %d", numel(calcsToRun), executionOrder);
                    obj.runCalculations(outputTime, calcsToRun, calcServerObj, coordLogger);
                    coordLogger.logInfo("Calculations complete for Execution Index: %d", executionOrder);
                end
            end
        end
        
        function runCalculations(obj, outputTime, calcsToRun, calcServerObj, logger)
            
            % Get Calculation Inputs & Parameters
            logger.logDebug("Get calculation inputs", []);
            %calcsToRun = obj.Calculations(indCalcs);
            for cI = 1:numel(calcsToRun)
                calcsToRun(cI).CalculationState = cce.CalculationState.FetchingData;
            end
            dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
            [inputs, parameters, successIdx, networkSuccessIdx] = cce.Calculation.getCalculationInputs(outputTime, calcsToRun,...
                dataConnector, "Logger", logger);

            % Remove inputs and parameters that weren't pulled
            inputs(~successIdx) = [];
            parameters(~successIdx) = [];

            %Change state of calcs that failed to correctly pull input data, before
            %removing them
            networkFailCalcs = calcsToRun(~networkSuccessIdx);
            
            for cI = 1:numel(networkFailCalcs)
                networkFailCalcs(cI).CalculationState = cce.CalculationState.Idle;
                networkFailCalcs(cI).LastError = "NetworkError";
            end

            calcsToRun(~networkSuccessIdx) = [];
            successIdx(~networkSuccessIdx) = [];
            
            failedInputCalcs = calcsToRun(~successIdx);
            for cI = 1:numel(failedInputCalcs)
                failedInputCalcs(cI).CalculationState = cce.CalculationState.SystemDisabled;
                failedInputCalcs(cI).LastError = "ConfigurationError";
                logger.logWarning("Calculation %s failed to get calulation inputs," + ...
                    " setting CalcState to SystemDisabled and LastError to ConfigurationError.",...
                    failedInputCalcs(cI).RecordPath);
            end
            calcsToRun(~successIdx) = [];

            %Check if no inputs were correctly pulled
            if isempty(calcsToRun)
                logger.logWarning("No calculations in coordinator for given execution index" + ...
                    " managed to retrieve inputs. Exiting runCalculations");
                return;
            end

            % Queue Calculations on the Calculation Server
            logger.logDebug("Queue calculations", []);
            queueResult = obj.queueCalculations(calcServerObj, inputs, parameters, calcsToRun);
            for cI = 1:numel(calcsToRun)
                calcsToRun(cI).CalculationState = cce.CalculationState.Queued;
                logger.logTrace("Calculation %s queued with id %s", calcsToRun(cI).RecordPath, queueResult(cI).id);
            end
            % Set a timeout for the Calculation run
            maxExecutionFrequency = max([calcsToRun.ExecutionFrequency]);
            if isnan(maxExecutionFrequency)
                maxExecutionFrequency = seconds(100*cce.System.CalcServerTimeout); % Arbitrary decision.
            end
            timeout = datetime('now') + maxExecutionFrequency;
            
            noOfExpectedResults = numel(calcsToRun);
            noOfResults = 0;
            resultsReceived = false(1, noOfExpectedResults);
            % While results still need to be returned and we have not passed the timeout
            % time
            outstandingResults = queueResult; % This will shrink over time
            logger.logTrace("Queued %d calculations with MLProdServer", numel(outstandingResults));
            queueRequestIDs = {queueResult.id};
            up = queueResult(1).up;
            createdSeq = queueResult(1).lastModifiedSeq;
            firstPass = true;

            while (numel(outstandingResults)>0) && (timeout > datetime('now'))
                % Request the status of the calculations from the Calculation Server
                logger.logTrace("Number of outstanding results: %d .", numel(outstandingResults));
                statusRequestResult = calcServerObj.requestCalculationState(createdSeq,up);
                statusRequestResult = calcServerObj.jsonDeserialisation(statusRequestResult);

                if firstPass 
                    createdSeq = statusRequestResult.createdSeq;
                    firstPass = false;
                end
                
               if ~isempty(statusRequestResult)
                    changedResults = statusRequestResult.data;
                    logger.logTrace("Received %d changed calculation states from MLProdServer", numel(changedResults));
                    % Process them in result order
                    mustDelete = false(1,numel(changedResults));
                    for ii = 1:numel(changedResults)
                        % Find which calc this refers to. We may not match if the ProdServer has outstanding requests from a prior call, so be
                        % careful here.
                        [~,calcIdx] = ismember(changedResults(ii).id, queueRequestIDs);
                        if (calcIdx>0) % We may have a stray calculation in the list that comes back; ignore it.
                            % Check the state of the result, if the Calculation is processing,
                            % set its state to Running and continue, if it has returned a
                            % result write the output to the DB, if it has
                            switch upper(string(changedResults(ii).state))
                                case {'READING', 'IN_QUEUE'}
                                    logger.logTrace("Calculation %s state = %s", calcsToRun(calcIdx).RecordPath, upper(string(changedResults(ii).state)));
                                case 'PROCESSING'
                                    logger.logTrace("Calculation Running: %s", calcsToRun(calcIdx).RecordPath);
                                    if (calcsToRun(calcIdx).CalculationState ~= cce.CalculationState.Running)
                                        calcsToRun(calcIdx).CalculationState = cce.CalculationState.Running;
                                    end
                                case 'READY'
                                    % Process the outputs and delete the request.
                                    readyCalc = calcsToRun(calcIdx);
                                    logger.logTrace("Calculation Ready: %s", readyCalc.RecordPath);
                                    % If the calculation wasn't in the Running state, fake it.
                                    if (readyCalc.CalculationState ~= cce.CalculationState.Running)
                                        logger.logTrace("Calculation set to Running after Outputs available: %s", readyCalc.RecordPath);
                                        readyCalc.CalculationState = cce.CalculationState.Running;
                                    end

                                    % Get and format the Calculation outputs
                                    result = calcServerObj.getCalculationResults(changedResults(ii));
                                    output = calcServerObj.formatCalcOutput(result);

                                    % Check if an output + a handled error (or good state)
                                    % are returned ot if an unhandled error has been
                                    % returned
                                    if isfield(output, 'error')
                                        % UNHANDLED ERROR: Returns the MException.
                                        output = output.error;
                                        % Write the returned error message to the logs
                                        logger.logError("Calculation Errored: %s, Error message: %s", ...
                                            readyCalc.RecordPath, output.message);
                                        % Set the Calculation LastError to UnhandledException
                                        lastCalcError = readyCalc.LastError;
                                        lastErr = getLastError(output.message);
                                        readyCalc.LastError = lastErr;

                                        % If the Calculation has had 2 consecutive UnhandledException LastError states,
                                        % set the Calculation State to Disabled
                                        if ~isIgnorableException(output.message) && ismember(lastCalcError, cce.CalculationErrorState.UnhandledException)
                                            readyCalc.CalculationState = cce.CalculationState.SystemDisabled;

                                            logger.logWarning("Calculation in same error state for two consecutive tries, disabling: %s, ErrorState: %s", ...
                                                readyCalc.RecordPath, lastCalcError);
                                        else
                                            readyCalc.CalculationState = cce.CalculationState.Idle;
                                        end

                                    else
                                        % OUTPUT + HANDLED ERROR (or Good): Returns an error code with the data even when it is good

                                        % Get the outputs and the returned cce.CalculationErrorState
                                        calcOutputs = output.lhs{1};
                                        errorCode = cce.CalculationErrorState(output.lhs{2}.mwdata);

                                        % Check if outputs returned are empty
                                        lastError = readyCalc.LastError;
                                        if any(structfun(@isempty, calcOutputs))
                                            %If any outputs are empty, set
                                            %the calculation to system
                                            %disabled, and set the error
                                            %state to NoResult

                                            readyCalc.CalculationState = cce.CalculationState.SystemDisabled;
                                            if (lastError == errorCode) || errorCode == cce.CalculationErrorState.Good %Unchanged error cod
                                                logger.logError("Calculation produced empty output/s: %s. Calculation disabled.", readyCalc.RecordPath);
                                                readyCalc.LastError = cce.CalculationErrorState.NoResult;

                                            else %Handled empty output
                                                logger.logError("Calculation errored, produced empty output/s: %s. Calculation disabled.", readyCalc.RecordPath);
                                                readyCalc.LastError = errorCode;
                                            end
                                            
                                        else
                                            timestamp = calcOutputs.Timestamp.mwdata.TimeStamp;
                                            if ~isnumeric(timestamp)
                                                % No outputs produced. Set LastError to NoResult
                                                logger.logWarning("Calculation Produced no values: %s", readyCalc.RecordPath);
                                                readyCalc.LastError = cce.CalculationErrorState.NoResult;
                                                errorCode = cce.CalculationErrorState.NoResult;
                                            else
                                                timestamp = timestamp/1000;
                                                calcOutputs.Timestamp = datetime(timestamp, 'convertFrom', 'posixtime');
                                                logger.logTrace("Calculation Writing Outputs: %s", readyCalc.RecordPath);
                                                readyCalc.CalculationState = cce.CalculationState.WritingOutputs;
                                                try
                                                    readyCalc.writeOutputs(calcOutputs);
                                                catch err
                                                    logger.logWarning("writeOuputs failed for calc %s. Error Message: %s", readyCalc.RecordPath, err.message)
                                                end
                                                readyCalc.LastError = errorCode;
                                                readyCalc.LastCalculationTime = outputTime;
                                            end
                                        end

                                        % Change calculation state to Disabled after the same 2 consecutive
                                        % non-good errorCodes are returned
                                        if readyCalc.CalculationState ~= cce.CalculationState.SystemDisabled %Only change the calc state if it
                                            % hasn't already been set to SystemDisabled
                                            if ismember(errorCode, lastError) && any(isFatal([errorCode, lastError]))
                                                logger.logWarning("Calculation in same error state for two consecutive tries, disabling: %s, ErrorState: %s", ...
                                                    readyCalc.RecordPath, errorCode);
                                                readyCalc.CalculationState = cce.CalculationState.SystemDisabled;
                                            else
                                                logger.logTrace("Calculation set to Idle: %s", readyCalc.RecordPath);
                                                readyCalc.CalculationState = cce.CalculationState.Idle;
                                            end
                                        end
                                    end
                                    noOfResults = noOfResults+1;
                                    resultsReceived(ii) = 1;
                                    mustDelete(ii) = true; % Defer deleting until the end.
                                case 'ERROR'
                                    erroredCalc = calcsToRun(calcIdx);
                                    errorResult = calcServerObj.getCalculationResults(changedResults(ii));
                                    errorResult = calcServerObj.jsonDeserialisation(errorResult);
                                    errorResult = errorResult.error;
                                    logger.logError("Calculation Errored: %s, Error Type: %s, Error Id: %s, Error Message: %s",...
                                        erroredCalc.RecordPath, errorResult.type, errorResult.messageId,...
                                        errorResult.message);

                                    priorCalcError = erroredCalc.LastError;
                                    erroredCalc.LastError = cce.CalculationErrorState.UnhandledException;

                                    if ismember(priorCalcError, cce.CalculationErrorState.UnhandledException)
                                        logger.logWarning("Calculation in same state for two consecutive tries, disabling: %s, ErrorState: %s", ...
                                            erroredCalc.RecordPath, string(cce.CalculationErrorState.UnhandledException));
                                        erroredCalc.CalculationState = cce.CalculationState.SystemDisabled;
                                    else
                                        logger.logTrace("Calculation set to Idle: %s", erroredCalc.RecordPath);
                                        erroredCalc.CalculationState = cce.CalculationState.Idle;
                                    end

                                    noOfResults = noOfResults + 1;
                                    resultsReceived(ii) = 1;
                                    mustDelete(ii) = true; % Defer deleting until the end.
                            end
                        else
                            logger.logTrace("Request result %s not found in calculations. Ignoring", changedResults(ii).id);
                        end
                    end
                    % Now delete the requests we've handled
                    requestsToDelete = changedResults(mustDelete);
                    % ensure that the correct calc in outstandingResults is removed
                    mustDeleteIdx = ismember({outstandingResults.id}, {requestsToDelete.id});
                    for dI = 1:numel(requestsToDelete)
                        logger.logTrace("Deleting handled request id %s", requestsToDelete(dI).self);
                        calcServerObj.deleteRequest(requestsToDelete(dI).self); %TODO: Check the result
                    end
                    
                    outstandingResults(mustDeleteIdx) = [];
                    logger.logTrace("Number of outstanding results after deletion: %d .", numel(outstandingResults))
               else
                   logger.logTrace("Recieved empty results for status request")
               end
            end

            % If the number of Calculation results returned was fewer than the number of
            % Calculations queued to run
            if noOfResults ~= noOfExpectedResults
                for ii=1:numel(calcsToRun)
                    if resultsReceived(ii) == 0
                        logger.logError("Timeout Error: %s", calcsToRun(ii).RecordPath);
                        calcsToRun(ii).CalculationState = cce.CalculationState.Idle;
                        calcsToRun(ii).LastError = cce.CalculationErrorState.QueueTimeout;
                    end
                end
                % Delete the outstanding results because we're not interested in the outputs any more
                for dI = 1:numel(outstandingResults)
                    % Delete this request.
                    try
                        calcServerObj.cancelRequest(outstandingResults(dI).self);
                        calcServerObj.deleteRequest(outstandingResults(dI).self);
                    catch MExc
                        logger.logError("Could not delete a queued calculation. Error was %s", MExc.identifier);
                    end
                end
            end
        end

        function checkLag(obj, coordinatorStartTime, execFreq, logger)
            % CHECKLAG checks if there are any lagging calculations and updates their last
            % calculation time if their SkipBackfill is set to true
            
            calculations = [obj.Calculations];
            skipBackfillIdx = [calculations.SkipBackfill];
            skipBackfillCalcs = calculations(skipBackfillIdx);

            if ~isempty(skipBackfillCalcs)
                laggingIdx = [skipBackfillCalcs.checkLag()];

                if any(laggingIdx)

                    for calc = [skipBackfillCalcs(laggingIdx)]
                        calc.LastCalculationTime = coordinatorStartTime - execFreq;
                        logger.logInfo("Updated last calculation time of calc: %s due to lag.", calc.RecordPath)
                    end
                end
            end
        end
        
        function nextOutputTime = getNextOutputTime(obj, coordinatorStartTime)
            %getNextOutputTime  Return the next calculation output time for a Calculation array
            %   t = getNextOutputTime(calcObj, defaultTime) returns the earliest next output time of all the
            %       calculations in calcObj. Any calculations with an invalid or default LastOutputTime are
            %       assumed to need outputs from defaultTime.

            calculations = [obj.Calculations];

            % Remove disabled calculations from calculation list to optimise coordinator overhead time
            idxEnabledCalculations = cce.isCalculationActive([calculations.CalculationState]);
            calculations(~idxEnabledCalculations) = [];

            % Guard against retrieveing NaT or (MinTime) for the LastCalcTime (Moved from inside for
            % loop for time optimisation)
            lastCalcTime = [calculations.LastCalculationTime];

            if ~isempty(lastCalcTime)
                idx = isnat(lastCalcTime) | (lastCalcTime.Year <= 1970);

                if any(idx)
                    for i = find(idx)
                    calculations(i).LastCalculationTime = coordinatorStartTime;
                    end
                end
            end
            
            %Check which calculations are ready
            isReady = false(size(calculations));
            nextCalcOutTimes = [calculations.NextOutputTime]; % Get all next output times instead of getting it in the loop            
            
            for ii = 1:length(calculations)
                [isReady(ii)] = calculations(ii).checkReadyToRun(nextCalcOutTimes(ii), obj.RetryFrequency,obj);            
            end

            %Only get min output time from ready calcs
            if any(isReady)
                nextOutputTime = min([nextCalcOutTimes(isReady)]);
            else
                nextOutputTime = NaT;
            end
        end
                
        function reenableSystemDisabledCalcs(obj)
            %REENABLESYSTEMDISABLEDCALCS finds all system disabled calcs in
            %given coordinator, and sets calc state to Idle

            % Find calculations that need to be reenabled
            calcStates = [obj.Calculations.CalculationState];
            reenableIdx = ismember(calcStates, cce.CalculationState.SystemDisabled);

            %Set states to Idle
            [obj.Calculations(reenableIdx).CalculationState] = deal(cce.CalculationState.Idle);

            %Set requestReenableFlag to false
            obj.ReenableSystemDisabledCalcs = false;
            obj.commit;

        end
    end
    methods (Static)

        function queueResult = queueCalculations(calcServerObj, inputs, parameters, calculations)
                        
            numOfOutputs = 2;
            numCalcs = numel(calculations);
            queueResult(numCalcs) = struct('id',[], 'self',[], 'up',[], 'lastModifiedSeq',[], 'state',[], 'client', []);
            for ii=1:length(calculations)
                archiveName = char(calculations(ii).ComponentName);
                functionName = char(calculations(ii).CalculationName);
                inputsToSend = {parameters{ii}, inputs{ii}};
                urlBody = calcServerObj.jsonSerialisation(inputsToSend, numOfOutputs);
                
                response = calcServerObj.queueCalculation(urlBody,...
                    archiveName, functionName);
                queueResult(ii) = calcServerObj.jsonDeserialisation(response);
            end
        end
    end
end
