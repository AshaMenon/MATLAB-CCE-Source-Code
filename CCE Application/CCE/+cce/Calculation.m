classdef Calculation < handle & matlab.mixin.CustomDisplay
    %cce.Calculation Calculation class
    %   The Calculation class contains details of a calculation that needs
    %   to be run.
    %
    %   The Calculation will be created using a Calculation
    %   Record. The Calculation will be stored in a Calculation
    %   database. A Calculation can be retrieved by calling
    %   Calculation.fetchFromDb.
    %
    %   Calculations have the following properties:
    %
    %   CoordinatorID: ID of the Coordinator to which the Calculation is assigned
    %   CalculationID: Unique ID of a calculation
    %   CalculationName: The name of the calculation to run
    %   CalculationMode: Determine whether a calculation should be run [automatic, disabled, manual_auto_reset, manual_once_off]
    %   ExecutionFrequency: How often the calculation should run
    %   ExecutionPriority: Level of priority that a calculation has - used
    %   for dependent calculations [high, medium, low]
    %   ExecutionIndex: Index required to determine which order to run calculations
    %   RequestToDisable: If true, a user requested that the calculation be disabled.
    %   WriteNanAs: If set to anything other than NaN, all output values as
    %   NaN are replaced with selected value. 
    %   CalculationState: The state that a calculation is in as it is being
    %       processed [not_configured, not_assigned, idle, fetching_data, queued, running, writing_outputs]
    %   LastCalculationTime: The last time that a calculation was run successfully
    %   LastError: The absolute last error that is returned by a calculation
    %   LogLevel: The required logging level for messages captured in the log file.
    %   LogName: Name of the Log file to which calculation errors will be written
    %   BackfillEnabled: A flag to determine whether a calculation should be backfilled or not
    %   BackfillOverwrite: A flag to determine whether a calculation should overwrite previous outputs
    %   BackfillEndTime: Time until which data should be available if backfilling has been enabled
    %   BackfillStartTime: Time from which data should be available if backfilling has been enabled
    %   SkipBackfill: A flag to determine if auto backfill should be skipped or not
    %   MissedRunsThreshold: Number of missed runs before lag is detected and auto backfill is
    %   skipped
    %   Autocommit: Automatically commit changes to the database as the CalculationRecord
    %   NextOutputTime: The next time that an output is required to be calculated for

    properties (SetAccess = 'private')
        RecordPath (1,:) string
        RecordName (1,:) string
    end

    properties (Dependent) % All dependent because we rely on the specific database implementation of CalculationRecord
        %ID of the Coordinator to which the Calculation is assigned
        CoordinatorID (1,1) int32
        %Unique ID of a calculation
        CalculationID (1,1) string
        %Calculation function to run on Calculation Server
        CalculationName (1,1) string
        %Name of the deployable archive hosting the calculation
        ComponentName (1,1) string
        %Offset time from midnight for the first calculation result in a day
        ExecutionOffset (1,1) duration
        %Calculation execution mode: Periodic, Event, or Manual
        ExecutionMode (1,1) cce.CalculationExecutionMode
        %Frequency of execution of a calculation (see ExecutionOffset)
        ExecutionFrequency (1,1) duration
        %Calculation execution depth (level of dependent calculations)
        ExecutionIndex (1,1) uint32
        %User request to disable calculation; if true, calculation must be disabled by the Coordinator
        RequestToDisable (1,1) logical;
        %How NaN values ouputted by calculation must be handled/replaced
        %by CCE
        WriteNanAs (1, 1) cce.WriteNanAsValue;
        %State of the calculation as it runs
        CalculationState (1,1) cce.CalculationState;
        %Last time that a calculation ran sucessfully
        LastCalculationTime (1,1) datetime
        %Last error returned by a calculation
        LastError (1,1) cce.CalculationErrorState
        %Logging level for calculation messages. See Logger class.
        LogLevel (1,1) int32
        %Name of the Log file to which calculation errors will be written
        LogName (1,1) string
        %State of backfilling for the calculation: Off, Requested, Running, Finished, Error
        BackfillState (1,1) cce.CalculationBackfillState
        %Percent (0-100) progress of backfilling run. See BackfillStartTime, BackfillEndTime.
        BackfillProgress (1,1) double
        %Last error returned by the calculation during backfilling run
        BackfillLastError (1,1) cce.CalculationErrorState
        %Flag to determine whether outputs should be overwritten
        BackfillOverwrite (1,1) cce.BackfillOverwrite
        %The data from a time that should be used for backfilling
        BackfillStartTime (1,1) datetime
        %The data until a time that should be used for backfilling
        BackfillEndTime (1,1) datetime
        %Automatically commit changes to database on set
        AutoCommit (1,1) logical
        %Next output time that a calculation needs to produce an output
        NextOutputTime (1,1) datetime
        %Flag to determine if auto backfill should be skipped
        SkipBackfill (1,1) logical
        %Threshold to determine lag
        MissedRunsThreshold (1,1) uint32
    end

    properties (Access = private)
        %Parameters associated with a calculation
        Parameters (1,:);
        %Inputs associated with a calculation
        Inputs (1,:);
        %Outputs associated with a calculation
        Outputs (1,:);
        %Trigger attributes associated with an event-based calculation
        Trigger (1, :);
    end

    properties (Access = private)
        % Implementation of the above properties
        DbRecord (1,1);
    end

    methods (Access = private)
        function obj = Calculation(dbInterface, inputsInterface, parametersInterface, outputsInterface, triggerInterface)
            %Calculation Construct a Calculation object
            %   A calculation has to be created using the static method: Calculation.fetchFromDb

            if nargin > 0
                for dI = numel(dbInterface):-1:1
                    obj(dI).DbRecord = dbInterface(dI);
                    obj(dI).RecordPath = dbInterface(dI).RecordPath;
                    obj(dI).RecordName = dbInterface(dI).RecordName;
                    obj(dI).Inputs = inputsInterface{dI};
                    obj(dI).Parameters = parametersInterface{dI};
                    obj(dI).Outputs = outputsInterface{dI};
                    obj(dI).Trigger = triggerInterface{dI};
                end
            end
        end
    end

    methods %Property setters and getters
        function id = get.CoordinatorID(obj)
            id = obj.DbRecord.getField("CoordinatorID");
        end
        function set.CoordinatorID(obj, val)
            obj.DbRecord.setField("CoordinatorID", val);
        end

        function id = get.CalculationID(obj)
            id = obj.DbRecord.getField("CalculationID");
        end

        function name = get.CalculationName(obj)
            name = obj.DbRecord.getField("CalculationName");
        end

        function name = get.ComponentName(obj)
            name = obj.DbRecord.getField("ComponentName");
        end

        function offset = get.ExecutionOffset(obj)
            offset = obj.DbRecord.getField("ExecutionOffset");
            if ~isa(offset, 'duration')
                offset = duration(0, 0, offset);
            end
            offset.Format = 's';
        end

        function mode = get.ExecutionMode(obj)
            mode = obj.DbRecord.getField("ExecutionMode");
            mode = cce.CalculationExecutionMode(mode);
        end

        function frequency = get.ExecutionFrequency(obj)
            frequency = obj.DbRecord.getField("ExecutionFrequency");
            if ~isa(frequency, 'duration')
                frequency = duration(0, 0, frequency);
            end
            frequency.Format = 's';
        end

        function index = get.ExecutionIndex(obj)
            index = obj.DbRecord.getField("ExecutionIndex");
        end

        function set.ExecutionIndex(obj, val)
            val = uint32(val);
            obj.DbRecord.setField("ExecutionIndex", val);
        end

        function val = get.RequestToDisable(obj)
            val = obj.DbRecord.getField("RequestToDisable");
        end
        function set.RequestToDisable(obj, val)
            val = logical(val);
            obj.DbRecord.setField("RequestToDisable", val);
        end
        function val = get.WriteNanAs(obj)
            val = obj.DbRecord.getField("WriteNanAs");
        end
        function state = get.CalculationState(obj)
            state = obj.DbRecord.getField("CalculationState");
            state = cce.CalculationState(state);
        end

        function set.CalculationState(obj, val)
            obj.DbRecord.setField("CalculationState", val);
        end

        function lastCalculationTime = get.LastCalculationTime(obj)
            lastCalculationTime = obj.DbRecord.getField("LastCalculationTime");
        end

        function set.LastCalculationTime(obj, val)
            obj.DbRecord.setField("LastCalculationTime", val);
        end

        function lastError = get.LastError(obj)
            lastError = obj.DbRecord.getField("LastError");
        end

        function set.LastError(obj, val)
            if isempty(val)
                val = cce.CalculationErrorState.Good;
            end
            obj.DbRecord.setField("LastError", val);
        end

        function logLevel = get.LogLevel(obj)
            logLevel = obj.DbRecord.getField("LogLevel");
        end

        function logName = get.LogName(obj)
            logName = obj.DbRecord.getField("LogName");
        end

        function backfillState = get.BackfillState(obj)
            backfillState = obj.DbRecord.getField("BackfillState");
        end
        function set.BackfillState(obj, val)
            obj.DbRecord.setField("BackfillState", val);
        end

        function progress = get.BackfillProgress(obj)
            progress = obj.DbRecord.getField("BackfillProgress");
        end
        function set.BackfillProgress(obj, val)
            obj.DbRecord.setField("BackfillProgress", val);
        end

        function lastError = get.BackfillLastError(obj)
            lastError = obj.DbRecord.getField("BackfillLastError");
        end
        function set.BackfillLastError(obj, val)
            obj.DbRecord.setField("BackfillLastError", val);
        end

        function overwrite = get.BackfillOverwrite(obj)
            overwrite = obj.DbRecord.getField("BackfillOverwrite");
        end

        function validUntilTime = get.BackfillEndTime(obj)
            validUntilTime = obj.DbRecord.getField("BackfillEndTime");
        end

        function validFromTime = get.BackfillStartTime(obj)
            validFromTime = obj.DbRecord.getField("BackfillStartTime");
        end

        function tf = get.AutoCommit(obj)
            tf = obj.DbRecord.AutoCommit;
        end
        function set.AutoCommit(obj, val)
            obj.DbRecord.AutoCommit = val;
        end
        function nextOutputTime = get.NextOutputTime(obj)
            nextOutputTime = cce.getNextOutputTime(obj.LastCalculationTime,...
                obj.ExecutionOffset, obj.ExecutionFrequency);
            nextOutputTime.Format = "dd-MM-yyyy hh:mm:ss";
        end

        function skipBackfill = get.SkipBackfill(obj)
            skipBackfill = obj.DbRecord.getField("SkipBackfill");
        end

        function missedRunsThreshold = get.MissedRunsThreshold(obj)
            missedRunsThreshold = obj.DbRecord.getField("MissedRunsThreshold");
        end
    end

    methods
        function backfillOutputTimes = getBackfillOutputTimes(obj, backfillStart, backfillEnd)
            %GETBACKFILLOUTPUTTIMES calculate the Calculation's Backfill Timestamps
            %between the range BACKFILLSTART and BACKFILLEND for the Calculation's
            %ExecutionOffset and ExecutionFrequency.

            lastCalculationTime = backfillStart - 0.5*obj.ExecutionFrequency;
            backfillStart = cce.getNextOutputTime(lastCalculationTime, ...
                obj.ExecutionOffset, obj.ExecutionFrequency);

            backfillOutputTimes = backfillStart:obj.ExecutionFrequency:backfillEnd;
        end

        function eventTimeStamps = getEventTimes(obj, backfillStart, backfillEnd)
            %GETEVENTTIMES find the Calculation's Trigger Event Timestamps for manual
            %backfilling between the range BACKFILLSTART and BACKFILLEND.

            eventTimeStamps = obj.Trigger.retrieveEventTimeStamps(backfillStart, backfillEnd);
        end

        function [isReady] = checkReadyToRun(obj, outputTime, timeToRetry, coordObj)
            %CHECKREADYTORUN checks whether a calculation can be run by ensuring that it
            %is in an active state and (if it is a dependent calculation) ensuring that
            %its dependent inputs are ready for the current OUTPUTTIME

            arguments
                obj cce.Calculation
                outputTime datetime
                timeToRetry double
                coordObj cce.Coordinator = cce.Coordinator.empty;
            end

            isReady = false;
            retryCalc = true;

            %Check if network error calculation can be reran
            if obj.LastError == cce.CalculationErrorState.NetworkError
                lastFailedTime = getNetworkFailedTime(obj.CalculationID);
                timeDiff = datetime("now") - lastFailedTime;

                if timeDiff < seconds(timeToRetry)
                    retryCalc = false;
                end
            end

            %Check the CalculationState - not retired, disabled, configuration error
            if retryCalc
                % Check the LastError if the Execution index is greater than 1
                if obj.ExecutionIndex > 1 && obj.LastError == cce.CalculationErrorState.DependentInputsNotReady
                    if checkInputsReadyToRun(obj, outputTime)
                        obj.LastError = cce.CalculationErrorState.Good;
                        isReady = true;
                    end
                else
                    isReady = true;
                end
            end
        end

        function clearOutputsTimeRange(obj, startTime, endTime)
            if numel(obj.Outputs)>0
                obj.Outputs.removeHistory(startTime, endTime);
            end
        end

        function isLagging = checkLag(obj)

            isLagging = [obj.LastCalculationTime] < datetime - [obj.ExecutionFrequency].*double([obj.MissedRunsThreshold]);
        end

        function runSingleCalculation(obj, args)
            %RUNSINGLECALCULATION runs a single calculation obj object without the
            %need for a coordinator.

            %Optional client ID for the calc server can be specified, along
            %with an optional logger
            arguments
                obj (1, 1) cce.Calculation
                args.ClientID string = sprintf('coordinator%d-%s', 0, char(datetime("now"), "yyyyMMddHHmmss"));
                args.Logger Logger = Logger("C:\CCE\calcLogs\testCalcs.log", "TestCalcs", "TestCalc1", "Trace") %Arbitrarily specified
                args.CalcTime (1, 1) datetime = datetime('now')
                args.DataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
            end

            logger = args.Logger;

            %Create CalcServer object - Use default host and port from config file.
            calcServerObj = CalcServer(args.ClientID);

            %Fetch data
            obj.CalculationState = cce.CalculationState.FetchingData;
            outputTime = args.CalcTime;
            [inputs, parameters, successIdx] = cce.Calculation.getCalculationInputs(outputTime, obj, args.DataConnector, "Logger", logger);

            %Change state of calcs that didnt correctly pull, before
            %removing them
            if ~successIdx
                obj.CalculationState = cce.CalculationState.SystemDisabled;
                obj.LastError = "ConfigurationError";
                logger.logWarning("Calculation %s failed to get calulation inputs, CalcState set to SystemDisabled and LastError set to ConfigurationError",...
                    obj.RecordPath);
                fprintf("Calculation %s failed to get calulation inputs.", obj.RecordPath); %Included verbose message since method used in testing.
                return
            end
            
            %Queue calc
            queueResult = cce.Coordinator.queueCalculations(calcServerObj, inputs, parameters, obj);
            obj.CalculationState = cce.CalculationState.Queued;

            maxExecutionFrequency = obj.ExecutionFrequency;
            if isnan(maxExecutionFrequency)
                maxExecutionFrequency = seconds(100*cce.System.CalcServerTimeout); % Arbitrary decision.
            end
            timeout = datetime('now') + maxExecutionFrequency;
            noOfExpectedResults = numel(obj);
            noOfResults = 0;
            resultsReceived = false(1, noOfExpectedResults);

            % While results still need to be returned and we have not passed the timeout
            % time
            outstandingResults = queueResult; % This will shrink over time
            queueRequestIDs = {queueResult.id};
            up = queueResult(1).up;
            createdSeq = queueResult(1).lastModifiedSeq;
            firstPass = true;

            while (numel(outstandingResults) > 0) && (timeout > datetime('now'))
                % Request the status of the calculations from the Calculation Server
                statusRequestResult = calcServerObj.requestCalculationState(createdSeq, up);
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

                    % Find which calc this refers to. We may not match if the ProdServer has outstanding requests from a prior call, so be
                    % careful here.
                    [~, calcIdx] = ismember(changedResults.id, queueRequestIDs);
                    if (calcIdx > 0) % We may have a stray calculation in the list that comes back; ignore it.
                        % Check the state of the result, if the Calculation is processing,
                        % set its state to Running and continue, if it has returned a
                        % result write the output to the DB, if it has
                        switch upper(string(changedResults.state))
                            case {'READING', 'IN_QUEUE'}
                                logger.logTrace("Calculation %s state = %s", obj(calcIdx).RecordPath, upper(string(changedResults.state)));
                            case 'PROCESSING'
                                logger.logTrace("Calculation Running: %s", obj(calcIdx).RecordPath);
                                if (obj(calcIdx).CalculationState ~= cce.CalculationState.Running)
                                    obj(calcIdx).CalculationState = cce.CalculationState.Running;
                                end
                            case 'READY'
                                % Process the outputs and delete the request.
                                readyCalc = obj(calcIdx);
                                logger.logTrace("Calculation Ready: %s", readyCalc.RecordPath);
                                % If the calculation wasn't in the Running state, fake it.
                                if (readyCalc.CalculationState ~= cce.CalculationState.Running)
                                    logger.logTrace("Calculation set to Running after Outputs available: %s", readyCalc.RecordPath);
                                    readyCalc.CalculationState = cce.CalculationState.Running;
                                end

                                % Get and format the Calculation outputs
                                result = calcServerObj.getCalculationResults(changedResults);
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
                                    readyCalc.LastError = cce.CalculationErrorState.UnhandledException;

                                    % If the Calculation has had 2 consecutive UnhandledException LastError states,
                                    % set the Calculation State to Disabled
                                    if ismember(lastCalcError, cce.CalculationErrorState.UnhandledException)
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
                                        %If any outputs are empty, disable
                                        %calculation, and set error state
                                        %to no result.

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
                                                logger.logWarning("writeOuputs failed for calc %s. Error Message: %s",...
                                                    readyCalc.RecordPath, err.message)
                                            end
                                            readyCalc.LastError = errorCode;
                                            readyCalc.LastCalculationTime = outputTime;
                                        end
                                    end

                                    % Change calculation state to Disabled after the same 2 consecutive
                                    % non-good errorCodes are returned.
                                    % Including no result
                                    if readyCalc.CalculationState ~= cce.CalculationState.SystemDisabled %Only change the calc state if it
                                        % hasn't already been set to SystemDisabled
                                        if ismember(errorCode, lastError) && (any(isFatal([errorCode, lastError])) ||...
                                                ismember(errorCode, cce.CalculationErrorState.NoResult))
                                            logger.logWarning("Calculation in same error state for two consecutive tries, disabling: %s, ErrorState: %s", ...
                                                readyCalc.RecordPath, errorCode);
                                            readyCalc.CalculationState = cce.CalculationState.SystemDisabled;
                                        else
                                            logger.logTrace("Calculation set to Idle: %s", readyCalc.RecordPath);
                                            readyCalc.CalculationState = cce.CalculationState.Idle;
                                        end
                                    end
                                end
                                noOfResults = noOfResults + 1;
                                resultsReceived = 1;
                                mustDelete = true; % Defer deleting until the end.
                            case 'ERROR'
                                erroredCalc = obj(calcIdx);
                                errorResult = calcServerObj.getCalculationResults(changedResults);
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
                                resultsReceived = 1;
                                mustDelete = true; % Defer deleting until the end.
                        end
                    else
                        logger.logTrace("Request result %s not found in calculations. Ignoring", changedResults.id);
                    end
                    % end
                    % Now delete the requests we've handled
                    requestsToDelete = changedResults(mustDelete);
                    mustDeleteIdx = ismember({outstandingResults.id}, {requestsToDelete.id});
                    for dI = 1:numel(requestsToDelete)
                        logger.logTrace("Deleting handled request id %s", requestsToDelete(dI).self);
                        calcServerObj.deleteRequest(requestsToDelete(dI).self); %TODO: Check the result
                    end
                    outstandingResults(mustDeleteIdx) = [];
                end
            end
            % If the number of Calculation results returned was fewer than the number of
            % Calculations queued to run

            % If the number of Calculation results returned was fewer than the number of
            % Calculations queued to run
            if noOfResults ~= noOfExpectedResults

                if resultsReceived == 0
                    logger.logError("Timeout Error: %s", obj.RecordPath);
                    obj.CalculationState = cce.CalculationState.Idle;
                    obj.LastError = cce.CalculationErrorState.QueueTimeout;
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

        function refreshAttributesForCyclicCoord(obj)
            for oI = 1:numel(obj)
                obj(oI).DbRecord.readRecordForCyclicCoord();
            end
        end
    end

    methods (Static)
        function obj = fetchFromDb(id, nvArgs)
            % Calculation.fetchFromDb  Load Calculations from database
            %   CalcObj = Calculation.fetchFromDb() retrieves all Calculations in the CCE System
            %       Calculation Database.
            %
            %   CalcObj = Calculation.fetchFromDb(id) retrieves the specific Calculations with the
            %       Coordinator ID from the CCE System Calculation Database.
            %
            %   CalcObj = Calculation.fetchFromDb(id, DatabaseService = DbService) retrieves
            %       the Calculations with Coordinator ID from the Calculation
            %       Database Service dbService. If id is empty, all Calculations are retrieved.
            %
            %   CalcObj = Calculation.fetchFromDb(id, Logger = logObj) utilises logObj for message
            %       logging.

            arguments
                id uint32 = [];
                nvArgs.DatabaseService (1,1) cce.ICalculationDbService = cce.System.getCalculationDbService();
                nvArgs.Logger = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel);
            end

            if isempty(id)
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = nvArgs.DatabaseService.findAllCalculations("Logger", nvArgs.Logger);
            else
                [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = nvArgs.DatabaseService.findCalculations(id, "Logger", nvArgs.Logger);
            end
            if ~isempty(calcRecords)
                obj = cce.Calculation(calcRecords, calcInput, calcParameter, calcOutput, calcTrigger);
            else
                obj = cce.Calculation.empty();
            end
        end
        function obj = createSingleCalc(afElement, dataConnector)
            %createSingleCalc uses an Element object instance, with a data
            %connector, to create a Calculation object, to be used in
            %testing.

            arguments
                afElement af.Element
                dataConnector af.AFDataConnector
            end

            %Create db service, and collect calc items
            dbService = cce.AFCalculationDbService.getInstance("DataConnector", dataConnector);
            [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = dbService.collectCalcItemsFromElement(afElement);

            %Create calculation
            if ~isempty(calcRecords)
                obj = cce.Calculation(calcRecords, calcInput, calcParameter, calcOutput, calcTrigger);
            else
                obj = cce.Calculation.empty();
                warning("No calculation records found, calculation empty.");
            end

        end

        function obj = fetchBackfillingFromDb(nvArgs)
            % Calculation.fetchBackfillingFromDb  Load Backfilling Calculations from database
            %   CalcObj = Calculation.fetchBackfillingFromDb() retrieves all Requested or
            %   Previously Running Backfilling Calculations in the CCE System Calculation
            %   Database.
            %
            %   CalcObj = Calculation.fetchFromDb('DatabaseService', DBService) retrieves
            %   the Backfilling Calculations from the Calculation Database Service
            %   dbService.

            arguments
                nvArgs.DatabaseService (1,1) cce.ICalculationDbService = cce.System.getCalculationDbService();
                nvArgs.Logger = Logger(cce.System.CoordinatorLogFile, "Coordinator", mfilename, cce.System.CoordinatorLogLevel);
            end

            [calcRecords, calcInput, calcParameter, calcOutput, calcTrigger] = nvArgs.DatabaseService.findBackfillingCalculations("Logger", nvArgs.Logger);
            if ~isempty(calcRecords)
                obj = cce.Calculation(calcRecords, calcInput, calcParameter, calcOutput, calcTrigger);
            else
                obj = cce.Calculation.empty();
            end
        end

        function [inputs, parameters, successIdx, networkSuccessIdx] = getCalculationInputs(outputTime, calculations, dataConnector, args)
            %GETCALCULATIONINPUTS retrieve the calculation inputs and parameters for the
            %given output time for each of the Coordinator's Calculations at the indices
            %INDCALCULATIONS

            arguments
                outputTime datetime
                calculations cce.Calculation
                dataConnector = af.AFDataConnector(cce.System.CalculationServerName, cce.System.CalculationDBName);
                args.Logger Logger = Logger
            end

            inputs = cell(1, length(calculations));
            parameters = cell(1, length(calculations));
            successIdx = true(1, length(calculations));
            networkSuccessIdx = true(1, length(calculations));
            failedConnectionCodes = string.empty;

            for c = 1:length(calculations)
                %Pull Input data
                try
                    inputs{c} = calculations(c).retrieveInputs(outputTime);
                catch err

                    if isempty(failedConnectionCodes)
                        failedConnectionCodesTbl = dataConnector.getTable("FailedConnectionCodes");
                        failedConnectionCodes = string(failedConnectionCodesTbl.Code);
                    end

                    if contains(err.message, failedConnectionCodes) || ~isConfigurationError(err.message)
                        args.Logger.logWarning("Connection failed when pulling input data on calculation %s,..." + ...
                            " writing network failed time.", calculations(c).RecordName)
                        writeNetworkErrorFailedTime(calculations(c).CalculationID, string(datetime),args.Logger)
                        networkSuccessIdx(c) = false;
                    end

                    inputs{c} = [];
                    successIdx(c) = false;
                    args.Logger.logWarning("Calculation %s couldnt pull input data. Error: %s",...
                        calculations(c).RecordName, err.message)
                end

                %Pull parameter data
                try
                    parameters{c} = calculations(c).retrieveParameters();
                    %Add additional CCE parameters
                    parameters{c}.CalculationID = calculations(c).CalculationID;
                    parameters{c}.CalculationName = calculations(c).CalculationName;
                    parameters{c}.LogLevel = calculations(c).LogLevel;
                    parameters{c}.LogName = calculations(c).LogName;
                    % Output Time must be UTC
                    pOutput = datetime(outputTime,"TimeZone","local");
                    pOutput.TimeZone = "UTC";
                    parameters{c}.OutputTime = string(pOutput,"uuuu-MM-dd'T'HH:mm:ss.SSS'Z'");
                catch err
                    parameters{c} = struct();
                    successIdx(c) = false;
                    args.Logger.logWarning(err.message)
                end
            end
        end
    end

    methods
        function [tf] = checkInputsReadyToRun(obj, outputTime, logger)%TODO: Remove basetime from calls
            %CHECKINPUTSREADYTORUN returns true/ false if all the Calculation's inputs are
            %available and ready for the Calculation to run.
            % If the Calculation's ExecutionIndex is 1, the Calculation is always ready to
            % run.
            % If a Calculation is dependent on another Calculation's outputs (i.e.
            % ExecutionIndex > 1) the Calculation must check if all of the Calculation's
            % inputs have been updated

            arguments
                obj
                outputTime
                logger = [];
            end

            if obj.ExecutionIndex == 1
                tf = true;
            elseif obj.ExecutionIndex > 1 && numel(obj.Inputs)>0
                if ~isempty(logger)
                    logger.logTrace("Checking if inputs ready for output time of: %s.", ...
                        string(outputTime, 'yyyy-MM-dd HH:mm:ss'))
                end
                [tf] = obj.Inputs(1).isReady(obj.CalculationID, outputTime);
            end
        end
        
        function [inputData] = retrieveInputs(obj, baseTime)
            %retrieveInputs  Fetch input data from calculation Inputs for a given time
            %   inputData = retrieveInputs(CObj, BbaseTime) retrieved the input data (a struct) from
            %       the inputs of CObj, given a calculation output time of baseTime.
            if numel(obj.Inputs)>0
                [inputData] = obj.Inputs.retrieveInputData(baseTime);
            else
                inputData = struct();
            end
        end

        function [parameters] = retrieveParameters(obj)
            if numel(obj.Parameters)>0
                [parameters] = obj.Parameters.retrieveParameters();
            else
                parameters = [];
            end
        end

        function writeOutputs(obj, outputData)
            if numel(obj.Outputs) > 0
                obj.Outputs.writeOutputData(outputData, 'WriteNanAs', obj.WriteNanAs);
            end
        end

        function name = retrieveInputNames(obj)
            if numel(obj.Inputs)>0
                name = [obj.Inputs.InputName];
            else
                name = string.empty;
            end
        end

        function [inputPIPoints] = retrieveInputPIPointPaths(obj)
            if numel(obj.Inputs)>0
                [inputPIPoints] = obj.Inputs.getInputPiPointPaths();
            else
                inputPIPoints = string.empty;
            end
        end

        function [outputPIPoints] = retrieveOutputPIPointPaths(obj)
            if numel(obj.Outputs)>0
                [outputPIPoints] = obj.Outputs.getOutputPiPointPaths();
            else
                outputPIPoints = string.empty;
            end
        end

        function [hasData] = checkOutputHasData(obj, timestamp)
            if numel(obj.Outputs)>0
                [hasData] = obj.Outputs.hasDataForTimestamp(timestamp);
            else
                hasData = logical.empty;
            end
        end

        function id = signUpForUpdateEvents(obj, dataPipe)

            id = obj.Trigger.signupForUpdateEvents(dataPipe, obj.CalculationID);
        end

        function removeForUpdateEvents(obj, dataPipe)

            obj.Trigger.signupForUpdateEvents(dataPipe, obj.CalculationID);
        end

        function isDisabled = checkForDisableRequest(obj)
            %checkDisableRequest Check RequestToDisable and disable if requested
            %   isDisabled = checkDisableRequest(obj)  checks if the user-drive RequestToDisable flag is true, and if so sets the calculation to
            %       Disabled and resets the RequestToDisable back to false.
            %       isDisabled is true where a calculation was disabled in this call.

            % Removed refreshing of attributes as this is now done in runCyclicCoordinator
            isDisabled = false(size(obj));
            mustDisable = [obj.RequestToDisable];
            alreadyDisabled = cce.isCalculationDisabled([obj.CalculationState]);
            mustDisable(alreadyDisabled) = false;
            for oI = 1:numel(obj)
                if mustDisable(oI)
                    % Disable this calculation
                    obj(oI).CalculationState = cce.CalculationState.Disabled;
                    obj(oI).RequestToDisable = false;
                    commit(obj(oI));
                    isDisabled(oI) = true;
                end
            end
        end
    end

    %Display Methods
    methods (Access = protected)
        function displayEmptyObject(obj)
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            fprintf('0x0 %s\n', objName);
        end
        function displayNonScalarObject(obj)
            indent = 4;
            objName = matlab.mixin.CustomDisplay.getClassNameForHeader(obj);
            dimStr = matlab.mixin.CustomDisplay.convertDimensionsToString(obj) ;
            fprintf('%s %s array:\n', dimStr, objName);
            fprintf('%s\n', '[R] Read-only, [A] Attribute, [P] Pi Point');
            displayTable = internal.DispTable;
            displayTable.Indent = indent;
            displayTable.ColumnSeparator = '  ';
            displayTable.addColumn('RecordName [R]', 'center');
            displayTable.addColumn('CalculationName [R]');
            displayTable.addColumn('CoordinatorID [A]');
            displayTable.addColumn('ExecutionIndex [A]');
            displayTable.addColumn('LastCalculationTime [P]');
            displayTable.addColumn('State [P]');
            displayTable.addColumn('LastError [P]');
            for k = 1:numel(obj)
                if isnat(obj(k).LastCalculationTime)
                    lastCalcTime = '';
                else
                    lastCalcTime = string(obj(k).LastCalculationTime);
                end
                if isempty(obj(k).LastError)
                    lastError = '';
                else
                    lastError = obj(k).LastError;
                end
                displayTable.addRow( ...
                    char(obj(k).RecordName), char(obj(k).CalculationName), ...
                    char(string(obj(k).CoordinatorID)), char(string(obj(k).ExecutionIndex)), char(lastCalcTime), ...
                    char(obj(k).CalculationState), char(lastError));
            end
            disp(displayTable);
        end
    end
end