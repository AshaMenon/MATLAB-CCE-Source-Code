function cceRestart(helpArg)
    %cceRestart  Restart CCE
    %   cceRestart performs the reverse of cceStop. All previously active CCE Coordinators are set to to
    %       NotRunning (from Disabled), all CCE Scheduled Tasks are reenabled, and the Scheduled Tasks
    %       for all Cyclic Coordinators will start immediately. Non-cyclic (single-shot) coordinators
    %       will run at their next execution cycle.
    %
    %   cceRestart -help displays this help.
    %
    %   See also: cceStop, cceStatus.

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum

    %% Manage the help argument
    if (nargin>0)
        if string(helpArg) == "-help"
            fprintf("%s\n", helpString());
            return;
        elseif string(helpArg) == "-runConfigurator"
            runConfigurator = true;
        else
            error("CCE:cceRestart:ArgumentInvalid", "Invalid argument passed to cceRestart. Use no arguments or ""-help"".");
        end
    else
        runConfigurator = false;
    end

    %% Logging setup
    logger = Logger(fullfile(cce.System.LogFolder, "system.log"), "", "CCERestart", "All"); % TODO: Control this
    logger.LogFileMaxSize = cce.System.LogFileMaxSize;
    logger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
    logger.logInfo("cceRestart starting.");


    try

        %% System check: If the activeCoordinators database does not exist, error.
        dbName = fullfile(cce.System.DbFolder, "activeCoordinators.mat");
        if ~exist(dbName, "file")
            logger.logError("cceStop has not been run: cannot execute cceRestart.");
            error("CCE:cceRestart:NotStopped", "cceStop has not been run: cannot execute cceRestart.");
        end

        %% Get the list of previously active coordinators
        fn = load(dbName);
        coordID = fn.coordID;
        logger.logInfo("Found %d Coordinators shut down by cceStop.", numel(coordID));

        %% Set the state of Coordinators to NotRunning
        for cI = 1:numel(coordID)
            thisID = coordID(cI);
            thisCoord = cce.Coordinator.fetchFromDb(thisID);
            if isempty(thisCoord)
                logger.logWarning("Previous Coordinator %d not found in PI AF.", thisID);
                % TODO: Remove scheduled task.
            else
                logger.logInfo("Setting Coordinator %d to NotRunning.", thisID);
                thisCoord.CoordinatorState = cce.CoordinatorState.NotRunning;
            end
        end

        %% Reenable all Scheduled Tasks (including the Configurator).
        schedulerFolder = cce.System.SchedulerFolderName;
        ws = WindowsScheduler;
        allCCETasks = ws.getTasksByFolder(schedulerFolder);

        if runConfigurator
            logger.logInfo("-runConfigurator argument inputted, running configurator...")
            configuratorTask = ws.getTaskByName("CCE Configurator", schedulerFolder);
            configuratorTask.enable;
            ws.runTask("CCE Configurator", schedulerFolder);

            %Wait for configurator to finish running
            completed = false;
            while ~completed
                pause(5); %Only check every 5 seconds
                if strcmpi(configuratorTask.State, "Ready")
                    completed = true;
                end
            end
            logger.logInfo("Configurator run completed.")
        end

        if (numel(allCCETasks) == 0)
            logger.logError("Could not find any Scheduled Tasks in CCE folder '%s'", schedulerFolder);
            error("CCE:cceRestart:NoScheduledTasks", "Could not find any Scheduled Tasks in CCE folder '%s'", schedulerFolder);
        end
        logger.logInfo("Reenabling %d Scheduled Tasks.", numel(allCCETasks));
        allCCETasks.enable;

        %% Restart the cyclic coordinators
        % We only restart the cyclic and event-based coordinators, because the others will run on schedule
        for tI = 1:numel(allCCETasks)
            taskName = allCCETasks(tI).Name;
            if startsWith(taskName, "CCE Coordinator")
                % Get the Coordinator ID from the name
                thisID = str2double(extractAfter(taskName, "CCE Coordinator #"));
                thisCoord = cce.Coordinator.fetchFromDb(thisID);
                if isempty(thisCoord)
                    logger.logWarning("Expected to find Coordinator %d but not found in database.", thisID);
                    % TODO: Is this a warning only or an error?
                else
                    if ismember(thisCoord.ExecutionMode, [cce.CoordinatorExecutionMode.Cyclic, cce.CoordinatorExecutionMode.Event, cce.CoordinatorExecutionMode.Manual])
                        % Run the scheduled task immediately.
                        logger.logInfo("Starting Scheduled Task for Coordinator %d", thisID);
                        try
                            allCCETasks(tI).run;
                        catch MExc
                            logger.logError("Could not run task for Coordinator %d. Message: %s", thisID, MExc.message);
                            warning("ons:cceRestart:CannotRunTask", "Could not start Coordinator %d. Please start manually.", thisID);
                        end
                    end
                end
            end
        end
        % Delete the database
        delete(dbName);
        logger.logInfo("cceRestart Exiting.")

    catch err
        logger.logError("cceRestart errored: %s", getReport(err))
    end
end

%% Helper functions
function str = helpString()
    %helpStr  Return the help for this function
    str=[...
        " cceRestart  Restart CCE"
        "    cceRestart performs the reverse of cceStop. All previously active CCE Coordinators are set to to"
        "        NotRunning (from Disabled), all CCE Scheduled Tasks are reenabled, and the Scheduled Tasks"
        "        for all Cyclic Coordinators will start immediately. Non-cyclic (single-shot) coordinators"
        "        will run at their next execution cycle."
        " "
        "    cceRestart -help displays this help."
        " "
        "    See also: cceStop, cceStatus."
        ];
end