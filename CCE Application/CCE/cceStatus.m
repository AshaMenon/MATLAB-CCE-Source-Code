function cceStatus(helpArg)
    %cceStatus  Display status of CCE Server Components
    %   cceStatus displays the status of components on the CCE server. The following data is displayed:
    %       CCE Configurator: Status of Scheduled Task (running/enabled/disabled)
    %       CCE Coordinators: Table showing state of each Coordinator
    %       Orphan Coordinator Scheduled Tasks: Scheduled tasks without a Coordinator record in PI AF
    %           (with their state)
    %
    %   ceStatus -help displays this help.
    %
    %   See also: cceStop, cceRestart.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum
    
    %% Manage the help argument
    if (nargin>0)
        if string(helpArg) == "-help"
            fprintf("%s\n", helpString());
            return;
        else
            error("CCE:cceRestart:ArgumentInvalid", "Invalid argument passed to cceRestart. Use no arguments or ""-help"".");
        end
    end
    
    %% Logging setup
    logger = Logger(fullfile(cce.System.LogFolder, "system.log"), "", "CCEStatus", "All"); %TODO: Control this
    logger.LogFileMaxSize = cce.System.LogFileMaxSize;
    logger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
    logger.logInfo("cceStatus starting.");
    fprintf("CCE Status:\n");
    
    %% Status of CCE Configurator
    schedulerFolder = cce.System.SchedulerFolderName;
    ws = WindowsScheduler;
    configTask = ws.getTaskByName("CCE Configurator", schedulerFolder);
    if isempty(configTask)
        fprintf("\tCCE Configurator Task not found.\n");
        logger.logWarning("CCE Configurator task not found.\n");
    else
        status = configTask.State;
        nextRun = configTask.NextRunTime;
        logger.logInfo("CCE Configurator State: %s; Next Run: %s", status, string(nextRun));
        fprintf("\tCCE Configurator: State = %s; Next run = %s\n", status, string(nextRun));
    end
    fprintf("\n");
    
    %% Status of CCE Coordinator tasks
    % The Coordinators are defined in PI AF and also as scheduled tasks. Base the status off the PI AF
    % system, but also report missing and/or extra scheduled tasks
    allCoordTasks = ws.getTasksByFolder(schedulerFolder);
    % Filter out the Configurator
    if ~isempty(allCoordTasks)
        allCoordTasks(ismember([allCoordTasks.Name], "CCE Configurator"))=[];
    end
    allCoords = cce.Coordinator.fetchFromDb();
    if isempty(allCoords)
        logger.logInfo("No Coordinators configured in PI AF system.")
        fprintf("No Coordinators found in PI AF.\n");
    else
        % We have some. Report on them
        fprintf("Coordinator Status:\n");
        isTaskAllocated = false(size(allCoordTasks));
        coordTaskName = [allCoordTasks.Name];
        taskState = strings(numel(allCoords), 1);
        taskNextRun = strings(numel(allCoords), 1);
        for cI = 1:numel(allCoords)
            % Find the corresponding Coordinator Scheduled Task, and remove it from the list
            if isempty(allCoordTasks)
                taskInd = [];
            else
                taskInd = ismember(coordTaskName, sprintf("CCE Coordinator #%d", allCoords(cI).CoordinatorID));
            end
            isTaskAllocated(taskInd) = true; % This happens even if there are multiple tasks defined.
            switch sum(taskInd)
                case 1 % Only one task. Normal behaviour
                    taskState(cI) = allCoordTasks(taskInd).State;
                    taskNextRun(cI) = string(allCoordTasks(taskInd).NextRunTime);
                case 0 % Task not found
                    logger.logWarning("Missing the scheduled task for Coordinator #%d", allCoords(cI).CoordinatorID);
                    taskState(cI) = "<missing>";
                    taskNextRun(cI) = "-";
                otherwise % Too many tasks
                    logger.logWarning("Found %d scheduled tasks for Coordinator #%d", allCoords(cI).CoordinatorID);
                    taskState(cI) = "<multiple>";
                    taskNextRun(cI) = "-";
            end
        end
        % And display this
        for cI = 1:numel(allCoords)
            % Coordinator <ID>: <State> [<Mode> (ExecutionFrequency +Offset), Lifetime <lifeTIme>,
            % <CalcualtionLoad> calcs.]
            %       AF State: <afState>.  Task State: <taskState>, Next Run <nextRumTime>
            cID = allCoords(cI).CoordinatorID;
            cState = allCoords(cI).CoordinatorState;
            cModeStr = allCoords(cI).ExecutionMode;
            if ismember(cModeStr, ["Cyclic", "Single"])
                if (seconds(allCoords(cI).ExecutionOffset) > 0)
                    cExecStr = string(allCoords(cI).ExecutionFrequency) + "+n(" + string(allCoords(cI).ExecutionOffset) + ")";
                else
                    cExecStr = string(allCoords(cI).ExecutionFrequency);
                end
            else
                cExecStr = "n/a";
            end
            cLifetimeStr = string(allCoords(cI).Lifetime);
            cLoad = allCoords(cI).CalculationLoad;
            fprintf("\t Coordinator %d: %s [%s, Lifetime=%s, Load=%d, Execution frequency=%s]\n", ...
                cID, cState, cModeStr, cLifetimeStr, cLoad, cExecStr);
            fprintf("\t\tTask State: %s, Next Run %s\n", taskState(cI), taskNextRun(cI));
        end
        % And report on the orphaned tasks
        if ~all(isTaskAllocated)
            orphanTasks = allCoordTasks(~isTaskAllocated);
            fprintf("Scheduled Tasks with no Coordinator record in PI AF:\n");
            for oI = 1:numel(orphanTasks)
                fprintf("\t%s (State = %s)\n", orphanTasks(oI).Name, orphanTasks(oI).State);
            end
        end
    end
    fprintf("\n");
    
    logger.logInfo("cceStatus exiting.");
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

function runningProc = findSystemProcess(processName)
    %findSystemProcess Return first instance of a specific system process
    proc = System.Diagnostics.Process.GetProcesses;
    procEnum = proc.GetEnumerator;
    runningProc = [];
    while procEnum.MoveNext
        if startsWith(string(procEnum.Current.ProcessName), processName)
            runningProc = procEnum.Current;
            break;
        end
    end
end


function str = helpString()
    %helpStr  Return the help for this function
    str=[...
        " cceStatus  Display status of CCE Server Components"
        "    cceStatus displays the status of components on the CCE server. The following data is displayed:"
        "        CCE Configurator: Status of Scheduled Task (running/enabled/disabled)"
        "        CCE Coordinators: Table showing state of each Coordinator"
        "        Orphan Coordinator Scheduled Tasks: Scheduled tasks without a Coordinator record in PI AF"
        "            (with their state)"
        " "
        "    ceStatus -help displays this help."
        " "
        "    See also: cceStop, cceRestart."
        ];
end