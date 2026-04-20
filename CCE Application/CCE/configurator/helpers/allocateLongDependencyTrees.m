function [coordinators] = allocateLongDependencyTrees(calculations, treeNumber, coordinators, lifetime, logger)
    %ALLOCATELONGDEPENDENCYTREES takes 'long' dependency trees, and evenly distributes the
    %Calculations (by ExecutionIndex) over the available + required new Coordinators.
    % Find active Coordinators that we can assign Calculations to
    activeCoordinators = coordinators(~ismember([coordinators.CoordinatorState], ...
        [cce.CoordinatorState.Disabled, cce.CoordinatorState.ForDeletion]));
    
    % Find the available CalculationLoad of the Coordinators
    coordCapacity = [activeCoordinators.MaxCalculationLoad] - [activeCoordinators.CalculationLoad];
    % Find the Coordinators' Execution Parameters
    executionMode = [activeCoordinators.ExecutionMode];
    executionFrequency = [activeCoordinators.ExecutionFrequency];
    executionOffset = [activeCoordinators.ExecutionOffset];
    skipBackfill = [activeCoordinators.SkipBackfill];
    
    % For each Tree
    for tree = unique(treeNumber)
        calcTree = calculations(treeNumber == tree);
        nCalcsThisTree = numel(calcTree);
        
        % If any of the Calculations are assigned to a Coordinator and the assignment is
        % not consistent for the whole tree:
        %   Remove the Calculations from the assigned Coordinators and reassign the tree.
        % Otherwise the tree is assigned to a Coordinator already - do nothing.
        idxNotAssigned = [calcTree.CalculationState] == cce.CalculationState.NotAssigned;
        if any(idxNotAssigned) || any([calcTree.CoordinatorID] ~= calcTree(1).CoordinatorID)
            
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
            
            %   Find the Coordinators that match the Calculation Tree's Execution Index
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
            idxHasCapacity = coordCapacity > 0;
            idxEligible = idxSameExecutionParams & idxHasCapacity;
            maxCalcLoad = getCalculationLoad(calcFrequency);
            %   Given the available Coordinators, calculate the available capacity and determine,
            %   if and how many Coordinators would need to be created to contain the entire tree &
            %   create the necessary Coordinators.
            if any(idxEligible)
                eligCoords = activeCoordinators(idxEligible);
                eligCapacity = coordCapacity(idxEligible);
                totalCapacity = sum(eligCapacity);
            else
                eligCoords = [];
                eligCapacity = [];
                totalCapacity = 0;
            end
            if totalCapacity < nCalcsThisTree
                numExtraCoords = ceil((nCalcsThisTree - totalCapacity)/ double(maxCalcLoad));
                for execIndex = 1:numExtraCoords
                    % Create a new Coordinator
                    mode = cce.CoordinatorExecutionMode(uint32(calcMode));
                    newCoord = createNewCoordinator([coordinators.CoordinatorID], ...
                        mode, calcFrequency, calcOffset, 0, lifetime, calcSkipBackfill);
                    
                    eligCoords = [eligCoords, newCoord]; %#ok<AGROW>
                    eligCapacity = [eligCapacity, maxCalcLoad]; %#ok<AGROW>
                    
                    coordinators = [coordinators, newCoord]; %#ok<AGROW>
                    
                    activeCoordinators = [activeCoordinators, newCoord]; %#ok<AGROW>
                    coordCapacity = [coordCapacity, maxCalcLoad]; %#ok<AGROW>
                    executionMode = [executionMode, mode]; %#ok<AGROW>
                    executionFrequency = [executionFrequency, calcFrequency]; %#ok<AGROW>
                    executionOffset = [executionOffset, calcOffset]; %#ok<AGROW>
                    skipBackfill = [skipBackfill, calcSkipBackfill]; %#ok<AGROW>
                    idxEligible = [idxEligible, true]; %#ok<AGROW>
                end
            end
            [eligCapacity, descOrder] = sort(eligCapacity, 'descend');
            eligCoords = eligCoords(descOrder);
            %   For each Execution Index (starting with the lowest Coordinator):
            %       For each Calculation in each Execution Index:
            %           Add a Calculation to each Coordinator
            whichCoord = 1;
            calcExecIndexes = [calcTree.ExecutionIndex];
            for execIndex = 1:max(calcExecIndexes)
                thisExecCalcs = calcTree(calcExecIndexes == execIndex);
                for calc = 1:numel(thisExecCalcs)
                    
                    addCalculationsToCoordinator(thisExecCalcs(calc), eligCoords(whichCoord))
                    
                    eligCapacity(whichCoord) = eligCoords(whichCoord).MaxCalculationLoad - eligCoords(whichCoord).CalculationLoad;
                    coordCapacity = [activeCoordinators.MaxCalculationLoad] - [activeCoordinators.CalculationLoad];
                    
                    if eligCapacity(whichCoord) == 0
                        eligCapacity(whichCoord) = [];
                        eligCoords(whichCoord) = [];
                    end
                    if whichCoord < numel(eligCoords)
                        whichCoord = whichCoord + 1;
                    else
                        whichCoord = 1;
                    end
                end
            end
        end
    end