function out = cceCoordinator(cID)
    %CCECOORDINATOR Execute a Coordinator for its lifetime
    %   CCECOORDINATOR(CID) executes a Coordinator with ID: CID. The configuration of the
    %   Coordinator is read form the Coordinator Database, specifying the Coordinators
    %   execution parameters, and its Lifetime. The Coordinator is run for its Lifetime
    %   (seconds) executing the periodic or event-driven calculations (read from the
    %   Calculation Database) assigned to this Coordinator.
    %
    %   See also: cceConfigurator | runCoordinator | runEventBasedCoordinator
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd.
    % developed as background IP for Anglo American Platinum
    
    if nargin<1 || isempty(cID)
        error("CCE:Coordinator:NoArgument", "cceCoordinator needs an argument.");
    end
    % The cID could be a string if this is deployed.
    if ischar(cID)
        try
            cID = str2double(cID);
        catch MExc
            error("CCE:Coordinator:InvalidArgument", "Could not convert '%s' into a number.", cID);
        end
    end
    
    try
        %Get the Coordinator start time
        coordinatorStartTime = datetime('now');
        
        % Get the log details
        logLevel = cce.System.CoordinatorLogLevel;
        logFileName = cce.System.CoordinatorLogFile;
        systemLogger = Logger(logFileName, "Coordinator", sprintf("Coordinator%d", cID), logLevel);
        systemLogger.LogFileMaxSize = cce.System.LogFileMaxSize;
        systemLogger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
        
        %% Setup the Coordinator by getting its properties and the calculations associated with it
        % The fetchFromDb function will get the details of a Coordinator with a
        % specified cID (Coordinator ID). The calculations that are associated
        % with that Coordinator will also be fetched.
        % Fetch coordinator as specified by cID. If this fails, retry in a backoff algorithm
        systemLogger.logInfo("Fetching Coordinator %d properties and calculations", cID);
        coordinatorObj = retrieveCoordinatorWithFallback(cID, systemLogger);
        if strlength(fileparts(coordinatorObj.LogName)) < 1
            logName = fullfile(cce.System.LogFolder, coordinatorObj.LogName);
        else
            logName = coordinatorObj.LogName;
        end
        
        coordLogger = Logger(logName, "Coordinator", sprintf("Coordinator%d", cID), coordinatorObj.LogLevel);
        coordLogger.LogFileMaxSize = cce.System.LogFileMaxSize;
        coordLogger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
        coordLogger.logInfo("Coordinator %d successfully started", cID);

        %% Reenable system disabled calculations if request is made
        if coordinatorObj.ReenableSystemDisabledCalcs
            coordLogger.logInfo("Reenabling SystemDisabled calculations on Coordinator%d", cID)
            coordinatorObj.reenableSystemDisabledCalcs;
        end
        
        %% Run the main Coordinator loop
        if ~isequal(coordinatorObj.CoordinatorState, cce.CoordinatorState.Disabled)
            %Set Coordinator state to starting
            coordLogger.logInfo("Starting coordinator %d", cID);
            coordinatorObj.CoordinatorState = cce.CoordinatorState.Starting;
            
            % Determine which coordinator algorithm to run
            executionMode = coordinatorObj.ExecutionMode;
            if ismember(executionMode, [cce.CoordinatorExecutionMode.Cyclic, cce.CoordinatorExecutionMode.Single])
                runCyclicCoordinator(coordinatorObj, cID, coordLogger, coordinatorStartTime);
            elseif ismember(executionMode, cce.CoordinatorExecutionMode.Event)
                runEventBasedCoordinator(coordinatorObj, cID, coordLogger, coordinatorStartTime);
            elseif ismember(executionMode, [cce.CoordinatorExecutionMode.Manual])
                runManualExecutionCoordinator(coordinatorObj, cID, coordLogger, coordinatorStartTime);
            else
                coordLogger.logError("Incorrect ExecutionMode %s passed to cceCoordinator %d.", coordinatorObj.ExecutionMode, cID);
            end
            
            % Set CoordinatorState to NotRunning and Exit
            setStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.NotRunning, coordLogger);
            coordLogger.logInfo("Coordinator %d exit time: %s", cID, char(datetime('now')));
        else
            coordLogger.logTrace("Coordinator %d run but in disabled state. Exiting.", cID);
        end
        out = 0;
        
    catch MExc
        out = -1; % Exit code -1 means error
        % Log error - Have to attempt to strip out the HTML reporting
        try
            systemLogger.logError("Error during Coordinator execution: %s ()", ...
                MExc.message, MExc.getReport("extended","hyperlinks","off"));
        catch
            systemLogger.logError("Error during Coordinator execution: %s ()", ...
                MExc.message, MExc.getReport());
        end
        % Set Coordinator to not running.
        if exist("coordinatorObj", "var") && ~isempty(coordinatorObj)
            setStateIfNotDisabled(coordinatorObj, cce.CoordinatorState.NotRunning, coordLogger);
        end
    end
end

%% Helper Functions
function setStateIfNotDisabled(coordObj, newState, logger)
    %setIfNotDisabled  Set Coordinator State as long as it's not disabled.
    if ~isequal(coordObj.CoordinatorState, cce.CoordinatorState.Disabled) && ...
            ~isequal(coordObj.CoordinatorState, newState)
        logger.logTrace("Setting coordinator state to %s", string(newState));
        coordObj.CoordinatorState = newState;
    end
end

function coordObj = retrieveCoordinatorWithFallback(cID, systemLogger)
    %retrieveCoordinatorWithFallback  Retrieve coordinator object with backoff retry.
    %   cObj = retrieveCoordinatorWithFallback(cID) attempts to retrieve Coordinator with ID cID, and if
    %   it fails with a possibly transient error, will retry in a backoff algorithm (pausing longer each
    %   time) until time runs out. In this case, time is defined by the system CoordinatorLifetime
    %   value. We will try for at most 20% of that lifetime.
    coordObj = cce.Coordinator.empty;
    timeToTry = seconds(cce.System.CoordinatorLifetime * 0.2);
    startTime = tic;
    dbName = fullfile(cce.System.DbFolder, sprintf("FetchFailRetryTime_Coordinator%d.mat", cID));
    if exist(dbName, 'file')
        fileContents = load(dbName);
        waitTime = fileContents.waitTime;
    else
        waitTime = min(2, timeToTry/100);
    end
    
    while isempty(coordObj) && (toc(startTime) < timeToTry)
        try
            systemLogger.logTrace("Trying to find Coordinator %d.", cID);
            coordObj = cce.Coordinator.fetchFromDb(cID);
            systemLogger.logTrace("Got back %d Coordinators.", numel(coordObj));
            % If successful, delete the retry database for this coordinator.
            [~, MExc.identifier] = lastwarn; % If we couldn't find one, we get a warning.
            if exist(dbName, "file")
                delete(dbName);
            end
        catch MExc
            errMsg = [MExc.stack(1).name, ' Line ',...
                num2str(MExc.stack(1).line), '. ', MExc.message];
            systemLogger.logWarning("Failed to retrieve Coordinator. Error was ""%s"". Waiting %d seconds.", string(errMsg), waitTime);
            pause(waitTime);
            waitTime = min(timeToTry, waitTime * 2); % Restrict the wait time to timeToTry.
            save(dbName, "waitTime");
        end
    end
    if isempty(coordObj)
        % Finally, error and say we couldn't fetch the coordinator.
        systemLogger.logError("Could not fetch Coordinator in required %d seconds.", timeToTry);
        if ~isa(MExc, "MException")
            % We couldn't find the Coordinator. Throw our own error
            MExc = MException("cce:cceCoordinator:RecordNotFound", "Could not find Coordinator with ID %d.", cID);
        end
        throwAsCaller(MExc);
    end
end

