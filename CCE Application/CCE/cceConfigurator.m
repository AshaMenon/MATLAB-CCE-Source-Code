function cceConfigurator(varargin)
    %CCECONFIGURATOR Run Configuration task for CCE
    %   CCECONFIGURATOR() allocates Coordinators for all CCECalculation elements in the PI
    %       AF Plant Database referenced in the [Calculations]AFPlantName entry of the CCE
    %       Main Configuration file. Deleted calculations are removed from their
    %       corresponding Coordinator execution set.
    %
    %       The CCE Main Configuration file location is C:\CCE\config\main.conf. If the
    %       environment variable CCE_Root is defined, then the configuration file
    %       is loaded from the config folder off of CCE_Root.
    
    % Copyright 2021 Opti-Num Solutions (Pty) Ltd
    % Version: $Format:%ci$ ($Format:%h$)
    % developed as background IP for Anglo American Platinum
    
    % The entire function is wrapped in a try..catch to catch and report on errors
    try
        configuratorElement = cce.Configurator();
        configuratorElement.ConfiguratorState = cce.ConfiguratorState.Running;

        % Read in some constants from the System
        lifetime = cce.System.CoordinatorLifetime;
        
        % Set up logging. This is guaranteed to succeed, even if it's just defaults.
        logLevel = configuratorElement.LogLevel;
        logFilename = fullfile(cce.System.LogFolder,configuratorElement.LogName);
        logger = Logger(logFilename, "Configurator", mfilename, logLevel);
        logger.LogFileMaxSize = cce.System.LogFileMaxSize;
        logger.LogFileBackupLimit = cce.System.LogFileBackupLimit;
        
        % Fetch all Coordinators from the Coordinator database and fetch all Calculations
        % from the Calculation database
        coordinators = cce.Coordinator.fetchFromDb([]);
        calculations = cce.Calculation.fetchFromDb([], "Logger", logger);
        logger.logInfo("Found %d Coordinator(s) and %d Calculation(s).", numel(coordinators), numel(calculations));

        %% check if all coordinators are properly configured
        misconfiguredIdx = findMisconfiguredCoordinators(coordinators);

        % Delete misconfigured coordinators 
        if any(misconfiguredIdx)
            misconfiguredCoords = coordinators(misconfiguredIdx);

            for coord = misconfiguredCoords
                try
                    logger.logInfo("Deleting coordinator %s.", string(coord.ElementName))
                    % coord.CoordinatorState = cce.CoordinatorState.ForDeletion;
                    deleteCoordinator(coord)
                    logger.logInfo("Deleted coordinator %s.", string(coord.ElementName))
                catch MExc
                    logger.logError("Failed to delete coordinator %s. Error: %s", string(coord.CoordinatorID), MExc.message)
                end
            end

            % refetch coordinators if there were misconfigured coordinators
            if any(misconfiguredIdx)
                coordinators = cce.Coordinator.fetchFromDb([]);
            end
        end
        
        %% Update Coordinator Loads
        for coord = 1:numel(coordinators)
            coordinators(coord).CalculationLoad = numel(coordinators(coord).Calculations);
        end
        
        %% Check Coordinator Calculation Loads, if too many calculations are found, offload & reassign them
        calculationLoads = [coordinators.CalculationLoad];
        maxCalculationLoads = [coordinators.MaxCalculationLoad];

        idxExcessiveLoad = find(calculationLoads > maxCalculationLoads);
        if ~isempty(idxExcessiveLoad)
            logger.logInfo("Offloading Calculations from %d overloaded Coordinator(s) for reallocation.", numel(idxExcessiveLoad));
            for overLoadCoord = 1:numel(idxExcessiveLoad)
                coordId = coordinators(idxExcessiveLoad(overLoadCoord)).CoordinatorID;
                idxCalculations = [calculations.CoordinatorID] == coordId;
                % Set the calculation's CoordinatorID to 0 and remove the Calculation Load from the
                % coordinator.
                excessCalcNum = calculationLoads(idxExcessiveLoad(overLoadCoord))...
                    - maxCalculationLoads(idxExcessiveLoad(overLoadCoord));
                calcsToRemove = calculations(idxCalculations);
                calcsToRemove = calcsToRemove(1:excessCalcNum);
                removeCalculationsFromCoordinators(calcsToRemove, coordinators, logger);
                
                % Reload calculations assigned to the coordinator
                coordinators(idxExcessiveLoad(overLoadCoord)).loadCalculations(logger);
            end
        end
        
        %% Create a Manual Execution Coordinator, If None Exist Already
        idxManualCoord = ismember([coordinators.ExecutionMode], cce.CoordinatorExecutionMode.Manual);
        if ~any(idxManualCoord)
            coordIds = [coordinators.CoordinatorID];
            logger.logTrace("Creating a Manual Coordinator", []);
            manualMode = cce.CoordinatorExecutionMode.Manual;
            manualCoord = createNewCoordinator(coordIds, manualMode, seconds(NaN), seconds(0), 0, cce.System.CoordinatorLifetime, false);
            coordinators = [coordinators, manualCoord];
            logger.logTrace("Manual Coordinator: %s created successfully.", manualCoord.CoordinatorID);
        end
        
        %% Find Calculation Dependencies and Set Execution Order
        % Find direct dependencies for each calculation
        directDependencies = cce.findDirectDependencies(calculations);
        if ~cce.System.TestMode
            storeDependentInputList(calculations, directDependencies);
        end
        % Find the execution order of each calculation
        [executionOrder, fullDependencyList, isDepChain] = cce.getExecutionOrder(calculations, directDependencies);
        setCalculationExecutionOrder(calculations, executionOrder, fullDependencyList, logger);
        
        %% Check if Dependent Calculations on the same tree have the correct Execution Parameters
        % Calculations on the same Dependency Tree must have:
        % - The same offset
        % - A frequency that is a multiple of its
        dependencyCalculations = calculations(isDepChain);
        % Find the full dependency list for each Calculation in a Dependency Tree
        % Find the individual Dependency Trees and which Calculations belong to each Tree
        fullChain = fullDependencyList(isDepChain);
        whichTree = findRelatedChains(dependencyCalculations, fullChain);
        for tree = 1:max(whichTree)
            treeCalcs = dependencyCalculations(whichTree == tree);
            verifyDependencyExecutionParameters(treeCalcs, fullChain(whichTree == tree));
        end
        
        %% Deleted Coordinators
        % Find any Calculations who are assigned to a Coordinator that has been deleted
        % (no longer found in the Coordinator database) or Calculations that are in an
        % active state but have no assigned Coordinator.
        % Set the CoordinatorID to 0 and for all active Calculations, set the State to
        % NotAssigned for reassignment.
        coordinatorID = [coordinators.CoordinatorID];
        assignedID = [calculations.CoordinatorID];
        assignedZeroCoord = assignedID == 0 & ~ismember([calculations.CalculationState],...
            [cce.CalculationState.NotAssigned, cce.CalculationState.Retired,...
            cce.CalculationState.Disabled, cce.CalculationState.SystemDisabled]); %RM Add ConfigurationError?

        isDeleted = (~ismember(assignedID, coordinatorID) & ~(assignedID == 0));
        if any(isDeleted | assignedZeroCoord)
            
            % Remove the CoordinatorID from all Calculations currently assigned to an
            % improperly Deleted Coordinator. If the Calculation is still in an active
            % state, set the Calculation to NotAssigned for reassignment later.
            deletedIDs = unAssignDeletedCoordinators(calculations, isDeleted, assignedZeroCoord, logger);
            deletedCoordinators = join(string(deletedIDs), ', ');
            
            %Remove Deleted Coordinator's Scheduled Task
            allCoordinatorTasks = findAllCoordinatorTasks();
            if ~isempty(allCoordinatorTasks)
                
                %Find which deleted Coordinators have Scheduled Task
                inArg = [allCoordinatorTasks.CommandArgument];
                idString = string(deletedIDs);
                [hasTask, locScheduled] = ismember(inArg, idString);
                locScheduled = locScheduled(hasTask);
                
                if any(hasTask)
                    for cID = 1:sum(hasTask)
                        removeScheduledTask(deletedIDs(locScheduled(cID)));
                    end
                    logger.logInfo("Removing %d Scheduler Task(s) for deleted Coordinator(s).\nDeleted Coordinator ID(s): #%s", sum(hasTask), deletedCoordinators);
                end
            end
        end
        
        %% Remove retired Calculations from assigned coordinators
        % Find Calculations that have been marked 'Retired' but have not been unassigned
        % from their Coordinator.
        % Remove the Calculation from the Coordinator (reduce the CalculationLoad) and
        % set the Calculation's CoordinatorID to 0.
        isNewlyRetired = ismember([calculations.CalculationState], cce.CalculationState.Retired) & ...
            [calculations.CoordinatorID] ~= 0;
        if any(isNewlyRetired)
            logger.logInfo("Removing %d retired Calculation(s).", sum(isNewlyRetired));
            removeCalculationsFromCoordinators(calculations(isNewlyRetired), coordinators, logger);
        else
            logger.logInfo("No newly retired Calculations.");
        end
        
        %% Remove modified calculations from assigned coordinators and set State as NotAssigned
        % Find active Calculations that are currently assigned to a Coordinator with
        % different Execution Parameters. Remove the Calculation from its current
        % Coordinator (reduce the CalculationLoad), set the Calculation's CoordinatorID to
        % 0, and set the CalculationState to NotAssigned for reassignment.
        
        isAssigned =  ~ismember([calculations.CalculationState], cce.CalculationState.NotAssigned) &...
            cce.isCalculationActive([calculations.CalculationState]);

        if any(isAssigned)
            logger.logInfo("Working with %d assigned Calculation(s).", sum(isAssigned));
            [isModified] = findModifiedCalculations(calculations(isAssigned), coordinators);
            
            if any(isModified)
                logger.logInfo("Reassigning %d modified Calculation(s).", sum(isModified));
                [indAssigned] = find(isAssigned);
                indModified = indAssigned(isModified);
                removeCalculationsFromCoordinators(calculations(indModified), coordinators);
                
                for k = 1:sum(isModified)
                    calculations(indModified(k)).CalculationState = cce.CalculationState.NotAssigned;
                    logger.logDebug("Calculation %s set to NotAssigned.", calculations(indModified(k)).CalculationName);
                end
            else
                logger.logInfo("No modified Calculations.", sum(isModified));
            end
        else
            logger.logInfo("No currently assigned Calculations.");
        end
        
        %% Find all Calculations allocated to Coordinator 0
        % There cannot be a Coordinator 0, but some people may have modified the CalculationState to
        % something other than NotAssigned. Set any Calculation with CoordinatorId==0 that is not
        % Unassigned, to Unassigned.
        isCoordinator0 = ([calculations.CoordinatorID]==0);
        isAssigned =  ~ismember([calculations.CalculationState], cce.CalculationState.NotAssigned) &...
            cce.isCalculationActive([calculations.CalculationState]);

        idxToBeReset = isCoordinator0 & isAssigned;
        if any(idxToBeReset)
            logger.logInfo("Setting %d Calculations to NotAssigned", sum(idxToBeReset));
            calculations(idxToBeReset).CalculationState = cce.CalculationState.NotAssigned;
        else
            logger.logTrace("No 'assigned' calculations with CoordinatorID 0 found.");
        end

        %% Find all Calculations to be assigned
        isUnassigned = ismember([calculations.CalculationState], cce.CalculationState.NotAssigned);
        isNotManual = ~ismember([calculations.ExecutionMode], cce.CalculationExecutionMode.Manual);
        idxToBeAssigned = isUnassigned & isNotManual;
        
        %% Create an Event-Based Coordinator, If None Exist Already && If there are Event Calculations to be Assigned
        idxEventCoord = ismember([coordinators.ExecutionMode], cce.CoordinatorExecutionMode.Event);
        idxEventToBeAssigned  = idxToBeAssigned & ...
            ismember([calculations.ExecutionMode], cce.CalculationExecutionMode.Event);
        if ~any(idxEventCoord) && any(idxEventToBeAssigned)
            coordIds = [coordinators.CoordinatorID];
            logger.logTrace("Creating an Event Coordinator", []);
            eventMode = cce.CoordinatorExecutionMode.Event;
            eventCoord = createNewCoordinator(coordIds, eventMode, seconds(NaN), seconds(0), 0, cce.System.CoordinatorLifetime, false);
            coordinators = [coordinators, eventCoord];
            logger.logTrace("Event Coordinator: %d created successfully.", eventCoord.CoordinatorID);
        end
        
        %% Assign all calculations in the 'NotAssigned' State to an appropriate Coordinator
        if any(idxToBeAssigned)
            logger.logInfo("Allocating %d unassigned Calculation(s).", sum(idxToBeAssigned));
            [coordinators] = allocateCalculationsToCoordinator(calculations, fullDependencyList, isDepChain, ...
                idxToBeAssigned, coordinators, lifetime, logger);
        else
            logger.logInfo("No unassigned Calculations.");
        end
        
        %% Create Scheduled Tasks for all in-use Coordinators that do not have an associated Scheduled Task
        % For all Coordinators that have a non-zero Calculation Load, and do not have a
        % Scheduled Task to run them, create the task.
        
        % Find Coordinators with a non-zero Calculation Load or is a Manual Coordinator
        hasLoad = [coordinators.CalculationLoad] ~= 0 | ...
            ismember([coordinators.ExecutionMode], cce.CoordinatorExecutionMode.Manual);
        if any(hasLoad)
            
            % Find which in-use Coordinators do not have a Scheduled Task
            coordIds = [coordinators.CoordinatorID];
            locLoad = find(hasLoad);
            [hasScheduledTask] = findCoordsWithTasks(coordinators(hasLoad));
            isMissingTask = ~hasScheduledTask;
            
            if any(isMissingTask)
                coordIds = coordIds(locLoad(isMissingTask));
                idString = join(string(coordIds), ', ');
                
                logger.logInfo("Attempting to create %d Coordinator Scheduled Task(s) for in-use Coordinator(s): #%s.", sum(isMissingTask), idString);
                
                offset = [coordinators(locLoad(isMissingTask)).ExecutionOffset];
                frequency = [coordinators(locLoad(isMissingTask)).ExecutionFrequency];
                repeatInterval = [coordinators(locLoad(isMissingTask)).Lifetime];
                for k = 1:numel(coordIds)
                    % Create the Scheduled Task for the in-use Coordinator.
                    logger.logTrace("Creating scheduled task for Coordinator %d: Offset = %s, Frequency = %s, Repeat = %s", ...
                        coordIds(k), string(offset(k)), string(frequency(k)), string(repeatInterval(k)));
                    thisTask = createScheduledTask(coordIds(k), offset(k), frequency(k), repeatInterval(k));
                    if isempty(thisTask) && ~cce.System.TestMode
                        [msg, warnID] = lastwarn;
                        if ismember(warnID, {'SchedulerTaskService:CannotCreateTask'})
                            logger.logError("Coordinator Scheduled Task for Coordinator #%d was not created. Last warning: %s", coordIds(k), msg);
                        else
                            logger.logError("Coordinator Scheduled Task for Coordinator #%d was not created.", coordIds(k));
                        end
                    end
                end
                
                %Check how many Scheduled Tasks were actually created
                [hasScheduledTask] = findCoordsWithTasks(coordinators(hasLoad));
                logger.logInfo("Successfully Created %d Scheduled Task(s) for %d unscheduled Coordinator(s).", ...
                    sum(hasScheduledTask), sum(isMissingTask));
            else
                logger.logInfo("No new Scheduled Task(s) created");
            end
        end
        
        %% Remove the Scheduled Task for all calculations with 0 CalculationLoad and mark them for deletion
        % For all Coordinators with a zero Calculation Load, remove the corresponding
        % Scheduled Task. If the Coordinator is no longer in a running state, mark the
        % Coordinator for deletion. If the Coordinator is still in a running state
        % (completing its last run), allow the Coordinator to finish, and set the
        if any(~hasLoad)
            logger.logInfo("Removing %d Scheduler(s) since Coordinator(s) have 0 load.", sum(~hasLoad));
            emptyCoords = coordinators(~hasLoad);
            [hasScheduledTask] = findCoordsWithTasks(emptyCoords);
            scheduledEmptyCoord = emptyCoords(hasScheduledTask);
            retireCoordinators([scheduledEmptyCoord.CoordinatorID]);
            
            coordinatorStates = [emptyCoords.CoordinatorState];
            isInactive = ismember(coordinatorStates, [cce.CoordinatorState.NotRunning, cce.CoordinatorState.Disabled]);
            if any(isInactive)
                indInactive = find(isInactive);
                for c = 1:sum(isInactive)
                    emptyCoords(indInactive(c)).CoordinatorState = cce.CoordinatorState.ForDeletion;
                end
                idString = join(string([emptyCoords(isInactive).CoordinatorID]), ', ');
                logger.logInfo("%d Coordinator(s): #%s have been marked 'ForDeletion'. CCE Admin must remove these Coordinators.", ...
                    sum(isInactive), idString);
            end
            
            isStillActive = ~ismember([emptyCoords.CoordinatorState], cce.CoordinatorState.ForDeletion);
            if any(isStillActive)
                activeEmptyCoordID = [emptyCoords(isStillActive).CoordinatorID];
                idString = join(string(activeEmptyCoordID), ', ');
                logger.logWarning(join(["The following Coordinator(s): #%s", ...
                    "have a zero load but are still in an executing state.",  ...
                    "\nThe associated Scheduled Tasks have been removed but", ...
                    "the Coordinators have not been marked 'ForDeletion'.", ...
                    "This may occur on the next CCE Configurator run."]), ...
                    idString)
            end
        else
            logger.logInfo("All Cyclic Coordinators have a non-zero Calculation Load");
        end
        
        configuratorElement.ConfiguratorState = cce.ConfiguratorState.NotRunning;

    catch MExc
        % Report the error and exit
        logger.logError("Class of exception received is %s", class(MExc));
        if isa(MExc, 'matlab.internal.validation.RuntimeNameValueException') || ...
                isa(MExc, 'matlab.internal.validation.RuntimePositionalException')
            logger.logError("Error during Configurator execution: %s", MExc.getReport());
        else
            logger.logError("Error during Configurator execution: %s", MExc.getReport("extended","hyperlinks","off"));
        end

        try
            configuratorElement.ConfiguratorState = cce.ConfiguratorState.Failed;
        catch err
            logger.logError("Error setting configurator state. Error message: %s", err.Message)
        end
    end
end
