function cceStop(killArg)
    %cceStop  Stop CCE
    %   cceStop disables all Coordinator Scheduled Tasks and sets all CCE Coordinators to Disabled.
    %       Normally this will stop all running CCE Coordinators when they can next terminate their
    %       execution. Use cceStop to suspend CCE calculations when you need to install an upgrade, or
    %       if the system becomes unstable and needs to be reset.
    %
    %       cceStop will not return until all running Coordinators have terminated. This should take no
    %       longer than one minute.
    %
    %   cceStop -kill also terminates all running CCE Coordinators. This option should be used as a last
    %       resort; normally a Coordinator will stop when it detects that the Coordinator’s state has
    %       been set to Disabled. If you use the “-kill” switch, there is no guarantee what state the
    %       Coordinator will be in when the process terminates, and there may be completed calculation
    %       results waiting to be retrieved from the CCE Calculation Server; those results will be
    %       remain in the Calculation Server output results folder until the Calculation Server is
    %       cleaned up.
    %
    %   cceStop -help displays this help.
    %
    %   See also: cceRestart, cceStatus.

    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum


    % Input checking - only one option
    if (nargin > 0)
        switch string(killArg)
            case "-help"
                fprintf("%s\n", helpString());
                return;
            case "-kill"
                mustKill = true;
            otherwise
                error("CCE:cceStop:ArgumentInvalid", "Invalid argument passed to cceStop. Use no arguments or ""-kill"".");
        end
    else
        mustKill = false;
    end

    %% Logging setup
    logger = Logger(fullfile(cce.System.LogFolder, "system.log"), "", "CCEStop", "All"); %TODO: Control this
    logger.LogFileMaxSize = cce.System.LogFileMaxSize;
    logger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
    logger.logInfo("cceStop starting.");

    try

        %% System check: If the activeCoordinators database exists, error.
        % Exception: Don't do this if we're in Kill mode, but also don't try to rewrite the database
        if mustKill
            logger.logInfo("-kill option specified");
        end

        dbName = fullfile(cce.System.DbFolder, "activeCoordinators.mat");
        mustDisable = true; % Do we stop Coordinators?
        if exist(dbName, "file")
            if mustKill % Don't exit just yet
                logger.logWarning("cceStop previously run. Kill option passed, so only stopping running Coordinator processes.");
                mustDisable = false;
            else % Didn't specify -kill and was run before. Error.
                logger.logError("cceStop has already been run: active Coordinator database exists.");
                error("CCE:cceStop:Rerun", "cceStop has already been run: active Coordinator database exists.");
            end
        end
        if ~exist(cce.System.DbFolder, "dir")
            logger.logWarning("Creating db folder %s.", cce.System.DbFolder);
            mkdir(cce.System.DbFolder);
        end

        %% Disable all Scheduled Tasks (including the Configurator).
        if mustDisable
            schedulerFolder = cce.System.SchedulerFolderName;
            ws = WindowsScheduler;
            logger.logTrace("Getting Scheduled Tasks");
            allCCETasks = ws.getTasksByFolder(schedulerFolder);
            if (numel(allCCETasks) == 0)
                logger.logError("Could not find any Windows Scheduled Tasks in CCE folder '%s'", schedulerFolder);
                warning("CCE:cceStop:NoScheduledTasks", "Could not find any Scheduled Tasks in CCE folder '%s'", schedulerFolder);
            else
                logger.logInfo("Disabling %d Scheduled Tasks.", numel(allCCETasks));
                disable(allCCETasks);
            end

            %% Store a list of active Coordinators locally in the db/activeCoordinators database. Coordinators are considered active if they are not in the Disabled, Retired or ForDeletion state.
            logger.logTrace("Getting Coordinators from DB");
            allCoords = cce.Coordinator.fetchFromDb();
            logger.logTrace("Found %d Coordinators in database.", numel(allCoords));
            activeCoords = allCoords(~isDisabled(allCoords));
            % Store in a local "database"
            coordID = [activeCoords.CoordinatorID];
            idStr = sprintf("%d, ", coordID);
            logger.logInfo("Active Coordinator IDs: %s", idStr.extractBefore(strlength(idStr)-1));
            coordState = [activeCoords.CoordinatorState];
            save(dbName, "coordID", "coordState");

            %% Set the State for all active Coordinators to Disabled.
            for k=1:numel(activeCoords)
                activeCoords(k).CoordinatorState = cce.CoordinatorState.Disabled;
            end
        end

        %% Check if we must kill running coordinators.
        if mustKill
            % Terminate all Coordinators (all processes with the name “cceCoordinator.exe”).
            proc = System.Diagnostics.Process.GetProcesses;
            procEnum = proc.GetEnumerator;
            killCount = 0;
            while procEnum.MoveNext
                if startsWith(string(procEnum.Current.ProcessName), "cceCoordinator")
                    procEnum.Current.Kill();
                    procEnum.Current.Dispose();
                    killCount = killCount + 1;
                end
            end
            logger.logInfo("Terminated %d cceCoordinator Processes.", killCount);
        else
            % Check the running state of all Coordinators (all processes with the name “cceCoordinator.exe”).
            % Wait at most 1 minute for all processes to terminate; if they have not terminated warn the user
            % and suggest then try the “-kill” switch.
            logger.logInfo("Waiting for running Coordinators to exit...");
            loopStart = datetime('now');
            loopDuration = minutes(1);
            stillRunning = true;

            while ((datetime('now') - loopStart) < loopDuration) && stillRunning
                numProcsRunning = countSystemProcess("cceCoordinator");
                stillRunning = (numProcsRunning > 0);
                if stillRunning
                    pause(0.2);
                end
            end
            if stillRunning
                logger.logWarning("Waited 1 minute, but %d cceCoordinator processes are still running.", numProcsRunning);
                warning("cce:cceStop:ProcessesStillRunning", ...
                    "%d Coordinators are still running. Terminate them manually or use the -kill option.", ...
                    numProcsRunning);
            end
        end
        logger.logInfo("cceStop exiting.");

    catch err
        logger.logError("cceStop errored: %s", getReport(err))
    end
end

%% Helper functions
function numProcesses = countSystemProcess(processName)
    %countSystemProcess Count instances of a specific system process sub-name
    proc = System.Diagnostics.Process.GetProcesses;
    procEnum = proc.GetEnumerator;
    numProcesses = 0;
    while procEnum.MoveNext
        % DEBUG: disp(char(procEnum.Current.ProcessName));
        if startsWith(string(procEnum.Current.ProcessName), processName)
            numProcesses = numProcesses + 1;
        end
    end
end

function str = helpString()
    %helpStr  Return the help for this function
    str=[...
        " cceStop  Stop CCE"
        "    cceStop disables all Coordinator Scheduled Tasks and sets all CCE Coordinators to Disabled."
        "        Normally this will stop all running CCE Coordinators when they can next terminate their"
        "        execution. Use cceStop to suspend CCE calculations when you need to install an upgrade, or"
        "        if the system becomes unstable and needs to be reset. "
        " "
        "        cceStop will not return until all running Coordinators have terminated. This should take no"
        "        longer than one minute."
        " "
        "    cceStop -kill also terminates all running CCE Coordinators. This option should be used as a last"
        "        resort; normally a Coordinator will stop when it detects that the Coordinator’s state has"
        "        been set to Disabled. If you use the “-kill” switch, there is no guarantee what state the"
        "        Coordinator will be in when the process terminates, and there may be completed calculation"
        "        results waiting to be retrieved from the CCE Calculation Server; those results will be"
        "        remain in the Calculation Server output results folder until the Calculation Server is"
        "        cleaned up."
        " "
        "    cceStop -help displays this help."
        " "
        "    See also: cceRestart, cceStatus."
        ];
end