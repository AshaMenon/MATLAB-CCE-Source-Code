function [coordinators] = allocateIndependentCalculations(calculations, coordinators, lifetime, logger)
    %ALLOCATEINDEPENDENTCALCULATIONS allocates a calculation to a coordinator with matching
    %run-signature, i.e. same execution frequency, execution offset, and execution mode.
    
    if ~isempty(coordinators)
        coordIds = [coordinators.CoordinatorID];
        coordinatorState = [coordinators.CoordinatorState];
        loads = [coordinators.CalculationLoad];
        maxLoads = [coordinators.MaxCalculationLoad];
        coordExecModes = [coordinators.ExecutionMode];
        coordExecFrequency = [coordinators.ExecutionFrequency];
        coordExecOffsets = [coordinators.ExecutionOffset];
        coordSkipBackfill = [coordinators.SkipBackfill];
    else
        coordIds = [];
        coordinatorState = [];
        loads = [];
        maxLoads = [];
        coordExecModes = [];
        coordExecFrequency = [];
        coordExecOffsets = [];
        coordSkipBackfill = [];
    end
    
    for k = numel(calculations):-1:1
        calc = calculations(k);
        executionMode = calc.ExecutionMode;
        skipBackfill = calc.SkipBackfill;
        
        isActiveCoord = ~ismember(coordinatorState, [cce.CoordinatorState.Disabled, cce.CoordinatorState.ForDeletion]);
        
        isPeriodic = executionMode == cce.CalculationExecutionMode.Periodic;
        isEvent = executionMode == cce.CalculationExecutionMode.Event;
        coordScheduleRepeatInterval = lifetime;
        if isPeriodic
            executionFrequency = calc.ExecutionFrequency;
            executionOffset = calc.ExecutionOffset;
            if executionFrequency >= cce.System.CoordinatorFrequencyLimit %RM why?
                executionMode = cce.CoordinatorExecutionMode.Single;
                coordScheduleRepeatInterval = executionFrequency;
            else
                executionMode = cce.CoordinatorExecutionMode.Cyclic;
            end
            
            %Find eligible coordinators in an active state with available load
            isModeMatch = coordExecModes == executionMode;
            isFrequencyMatch = coordExecFrequency == executionFrequency | (isnan(coordExecFrequency) & isnan(executionFrequency));
            isOffsetMatch = coordExecOffsets == executionOffset;
            isSkipBackfillMatch = coordSkipBackfill == skipBackfill;
            isMatchingExecution = isModeMatch & isFrequencyMatch & isOffsetMatch & isActiveCoord & isSkipBackfillMatch;
            
            hasAvailableLoad = loads < maxLoads;
            isEligibleCoord = isMatchingExecution & hasAvailableLoad;
            
        elseif isEvent
            executionMode = cce.CoordinatorExecutionMode.Event;
            isEventCoord = coordExecModes == executionMode;
            isEligibleCoord = isEventCoord & isActiveCoord;
            
            executionFrequency = seconds(NaN);
            executionOffset = seconds(0);
        end
        
        if any(isEligibleCoord)
            allEligibleIds = coordIds(isEligibleCoord);
            [~, indMinEligLoad] = min(loads(isEligibleCoord));
            assignedID = allEligibleIds(indMinEligLoad);
            
            indAssignedCoord = find(coordIds == assignedID);
            assignedCoord = coordinators(indAssignedCoord);
        else %Create a new coordinator if none are avaliable
            
            mode = cce.CoordinatorExecutionMode(uint32(executionMode));
            load = 0;
            maxLoad = getCalculationLoad(executionFrequency);
            assignedCoord = createNewCoordinator(coordIds, ...
                mode, executionFrequency, executionOffset, ...
                load, coordScheduleRepeatInterval, skipBackfill);
            
            logger.logInfo("Created new Coordinator ID: %d", assignedCoord.CoordinatorID);
            
            coordinators = [coordinators, assignedCoord]; %#ok<AGROW>
            coordIds = [coordIds, assignedCoord.CoordinatorID]; %#ok<AGROW>
            loads = [loads, load]; %#ok<AGROW>
            maxLoads = [maxLoads, maxLoad]; %#ok<AGROW>
            coordExecModes = [coordExecModes, mode]; %#ok<AGROW>
            coordExecFrequency = [coordExecFrequency, executionFrequency]; %#ok<AGROW>
            coordExecOffsets = [coordExecOffsets, executionOffset]; %#ok<AGROW>
            coordinatorState = [coordinatorState, assignedCoord.CoordinatorState]; %#ok<AGROW>
            coordSkipBackfill = [coordSkipBackfill, skipBackfill]; %#ok<AGROW>
            
            indAssignedCoord = numel(coordinators);
        end
        
        if (isPeriodic || isEvent) && exist('assignedCoord', 'var')
            addCalculationToCoordinator(assignedCoord, calc);
            loads(indAssignedCoord) = loads(indAssignedCoord) + 1;
        else
            if ~executionMode == cce.CalculationExecutionMode.Manual
                logger.logInfo("Unassigned Calculation: ID, has unrecognised", assignedCoord.CoordinatorID);
            end
        end
    end
end
