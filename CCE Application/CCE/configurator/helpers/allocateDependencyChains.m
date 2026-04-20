function [coordinators] = allocateDependencyChains(calculations, calculationChainNumber, coordinators, lifetime, logger)
    
    % Get the configuration of the existing coordinators
    if ~isempty(coordinators)
        coordIDs = [coordinators.CoordinatorID];
        loads = [coordinators.CalculationLoad];
        coordinatorState = [coordinators.CoordinatorState];
    else
        coordIDs = [];
        loads = [];
        coordinatorState = [];
    end
    
    % For all calculations in related chains, assign them to the same Coordinator
    chainNumber = unique(calculationChainNumber);
    for chain = 1:numel(chainNumber)
        idxRelatedCalcs = calculationChainNumber == chainNumber(chain);
        relatedCalcs = calculations(idxRelatedCalcs);
        calcCoordIDs = [relatedCalcs.CoordinatorID];
        freq = min([relatedCalcs.ExecutionFrequency]);
        offset = min([relatedCalcs.ExecutionOffset]);
        
        assignedCoordIDs = unique(calcCoordIDs(calcCoordIDs ~= 0));
        % If any of the related Calculations are already assigned to the same Coordinator,
        % and the Coordinator is only used for these Dependent Calculations then use this
        % Coordinator
        if numel(assignedCoordIDs) == 1 && loads(ismember(assignedCoordIDs, coordIDs)) == sum(calcCoordIDs ~= 0) && ...
                ismember(assignedCoordIDs, coordIDs) && ...
                ~ismember(coordinatorState(ismember(assignedCoordIDs, coordIDs)), ...
                [cce.CoordinatorState.Disabled, cce.CoordinatorState.ForDeletion])
            
            % Check Execution Frequency, and Offset - If they do not match the minimum,
            % remove the scheduled task - will be created later and reset the
            % Execution Parameters
            assignedCoord = coordinators(coordIDs == assignedCoordIDs);
            if assignedCoord.ExecutionFrequency ~= freq || assignedCoord.ExecutionOffset ~= offset
                % Remove scheduled task
                retireCoordinators(coordinatorIDs);
                % Set Execution Parameters
                assignedCoord.ExecutionFrequency = freq;
                assignedCoord.ExecutionOffset = offset;
            end
        else
            % A Dependent Calculations Coordinator does not exist for this set of related
            % calculation chain(s). Remove any Calculations previously assigned to a
            % Coordinator
            if any(assignedCoordIDs)
                %Remove all calculations from their Coordinator and reassign to a new one
                removeCalculationsFromCoordinators(relatedCalcs(calcCoordIDs ~= 0), coordinators, logger);
            end
            %Create a new Coordinator for these related Calculations
            mode = cce.CoordinatorExecutionMode.Cyclic; %FIXME: what about other types
            load = 0;
            assignedCoord = createNewCoordinator(coordIDs, mode, freq, offset, load, lifetime);
            
            coordinators = [coordinators, assignedCoord]; %#ok<AGROW>
            coordIDs = [coordIDs, assignedCoord.CoordinatorID]; %#ok<AGROW>
            loads = [loads, load]; %#ok<AGROW>
        end
        
        % Assign all the calculations in the related chains to the same Coordinator
        whichCoord = coordinators == assignedCoord;
        coordID = assignedCoord.CoordinatorID;
        relatedCalcIDs = [relatedCalcs.CoordinatorID];
        for calcs = 1:numel(relatedCalcs)
            if relatedCalcIDs(calcs) ~= coordID
                addCalculationToCoordinator(assignedCoord, relatedCalcs(calcs))
                loads(whichCoord) = loads(whichCoord) + 1;
            end
        end
    end
end