function [coordinators] = allocateShortDependencyTrees(calculations, treeNumber, coordinators, lifetime, logger)
    %ALLOCATESHORTDEPENDENCYTREES takes 'short' dependency trees, treats all Calculations
    %in the tree as an atomic unit and assigns the Calculations to the same Coordinator
    
    % Find active Coordinators that we can assign Calculations to
    activeIdx = ~ismember([coordinators.CoordinatorState], ...
        [cce.CoordinatorState.Disabled, cce.CoordinatorState.ForDeletion]);
    activeCoordinators = coordinators(activeIdx);
    
    % Find the available CalculationLoad of the Coordinators
    coordCapacity = [activeCoordinators.MaxCalculationLoad] - [activeCoordinators.CalculationLoad];
    % Find the Coordinators' Execution Parameters
    executionMode = [activeCoordinators.ExecutionMode];
    executionFrequency = [activeCoordinators.ExecutionFrequency];
    executionOffset = [activeCoordinators.ExecutionOffset];
    skipBackfill = [activeCoordinators.SkipBackfill];
    
    %BEST-FIT BIN PACKING ALGORITHM
    % -----------------------------
    %
    % Add the item to the bin that contain it leaving the least remaining capacity (for
    % the bin). If it doesn't fit into any of the bins, create & add it to a new bin.
    % For each calculation tree:
    for tree = unique(treeNumber)
        calcTree = calculations(treeNumber == tree);
        nCalcsThisTree = numel(calcTree);
        
        % If any of the Calculations are assigned to a Coordinator and the assignment is
        % not consistent for the whole tree:
        %   Remove the Calculations from the assigned Coordinators and reassign the tree.
        % Otherwise the tree is assigned to a Coordinator already - do nothing.
        idxNotAssigned = [calcTree.CalculationState] == cce.CalculationState.NotAssigned;
        if any(idxNotAssigned) || any([calcTree.CoordinatorID] ~= calcTree(1).CoordinatorID)
            
            % Set the coordinator max load to system max load (otherwise
            % it'll create a new coordinator, and not use this one at all)
            usedCoordIdx = ismember([activeCoordinators.CoordinatorID], [calcTree.CoordinatorID]);

            if any(usedCoordIdx)
                %Get coordinators used by the tree
                usedCoordinator = activeCoordinators(usedCoordIdx);
                if numel(usedCoordinator) > 1
                        logger.logWarning("Short dependency chain calcs were assigned to multiple coordinators. Coordinators: %s",...
                            regexprep(num2str([usedCoordinator.CoordinatorID]),'\s+',','));
                end

                %Loop through coordinators, setting their Max calc load to
                %respective max calc load
                for iCoord = 1:numel(usedCoordinator)
                    if nCalcsThisTree > usedCoordinator(iCoord).MaxCalculationLoad
                        maxCalcLoad = getCalculationLoad(usedCoordinator(iCoord).ExecutionFrequency);
                        usedCoordinator(iCoord).MaxCalculationLoad = maxCalcLoad;
                        usedCoordinatorID = usedCoordinator(iCoord).CoordinatorID;
                        logger.logWarning("Reset Coordinator ID: %u MaxCalculationLoad to" +...
                            " system default, as a short dependency chain exceeds user specified load.",...
                            usedCoordinatorID);
                    end

                end

            end

            % Remove assigned Calculations from the assigned Coordinators
            idxNonZero = [calcTree.CoordinatorID] ~= 0;
            idxAssignedCalc = idxNonZero | ~idxNotAssigned;
            if any(idxAssignedCalc)
                removeCalculationsFromCoordinators(calcTree(idxNonZero), coordinators, logger);
                % Set any previously assigned active Calculations to the NotAssigned state
                idxActive = cce.isCalculationActive([calcTree.CalculationState]);
                if any(idxActive)
                    notAssignedStateCell = repmat({cce.CalculationState.NotAssigned}, size(calcTree(idxActive)));
                    [calcTree(idxActive).CalculationState] = notAssignedStateCell{:};
                end
                coordCapacity = [activeCoordinators.MaxCalculationLoad] - [activeCoordinators.CalculationLoad];
            end

            
            % Find the Execution Parameters for the Calculation Tree:
            %	If any of the Calculations have different execution parameters:
            %       Use the lowest offset and lowest execution frequency and cyclic mode
            calcMode = [calcTree.ExecutionMode];
            calcFrequency = [calcTree.ExecutionFrequency];
            calcOffset = [calcTree.ExecutionOffset];
            calcSkipBackfill = [calcTree.SkipBackfill];
            [calcMode, calcFrequency, calcOffset, calcSkipBackfill] = ...
                findCalculationTreeExecutionParameters(calcMode, calcFrequency, calcOffset, calcSkipBackfill, logger);
            
            % Find Coordinators with the matching Execution Parameters:
            idxSameExecutionParams = (executionMode == calcMode) & ...
                (executionFrequency == calcFrequency | ...
                (isnan(executionFrequency) & isnan(calcFrequency))) & ...
                (executionOffset == calcOffset) & (skipBackfill == calcSkipBackfill);
            % Find Coordinators that have enough CalculationLoad capacity to contain this
            % tree.
            idxHasCapacity = coordCapacity >= nCalcsThisTree;
            idxEligible = idxSameExecutionParams & idxHasCapacity;

            % If a Coordinator exists with the same Execution Parameters, and has enough
            % space for all of the Calculations in the Calculation Tree:
            %   Add the Calculations to the Coordinator with the least capacity (highest
            %   CalculationLoad).
            % Otherwise:
            %   Create a new Coordinator.
            %   Add the Calculations to the new Coordinator.
            if any(idxEligible)
                eligCoords = activeCoordinators(idxEligible);
                eligCapacity = coordCapacity(idxEligible);
            else
                % Create a new Coordinator
                mode = cce.CoordinatorExecutionMode(uint32(calcMode));
                eligCoords = createNewCoordinator([coordinators.CoordinatorID], ...
                    mode, calcFrequency, calcOffset, 0, lifetime, calcSkipBackfill);
                maxCalcLoad = getCalculationLoad(calcFrequency);
                eligCapacity = maxCalcLoad; 
                
                coordinators = [coordinators, eligCoords]; %#ok<AGROW>
                activeCoordinators = [activeCoordinators, eligCoords]; %#ok<AGROW>
                coordCapacity = [coordCapacity, maxCalcLoad]; %#ok<AGROW>
                executionMode = [executionMode, mode]; %#ok<AGROW>
                executionFrequency = [executionFrequency, calcFrequency]; %#ok<AGROW>
                executionOffset = [executionOffset, calcOffset]; %#ok<AGROW>
                skipBackfill = [skipBackfill, calcSkipBackfill]; %#ok<AGROW>
                idxEligible = [idxEligible, true]; %#ok<AGROW>
            end
            
            % Add the Calculations in this tree to the selected Coordinator
            [~, indCoord] = min(eligCapacity);
            treeCoordinator = eligCoords(indCoord);
            addCalculationsToCoordinator(calcTree, treeCoordinator);
            coordCapacity(idxEligible(indCoord)) = treeCoordinator.MaxCalculationLoad - treeCoordinator.CalculationLoad;
        end
    end
end