function [executionOrder, fullDependencyList, isDepChain] = getExecutionOrder(calculations, dependencies)
    %GETEXECUTIONORDER finds the execution order, and full dependency chain for the
    %cce.Calculations in CALCULATIONS

    %calculations - list of all calculations
    %dependencies - cell containing dependee calculations for each depender
    %calc. Cells are empty for calcs that depend on no other calcs. 
    
    if isa(calculations, 'cce.Calculation')
        calcID = [calculations.CalculationID];
        dependID = cellfun(@(c) getDependentCalculationID(c), dependencies, 'UniformOutput', false);
    else
        calcID = calculations;
        dependID = dependencies;
    end
    
    % Initialise the EXECUTIONORDER
    executionOrder = zeros(size(calculations));
    % For each Calculation that does not have any direct dependencies, its EXECUTIONORDER
    % will be one and it will be marked as true (already visited) in the VISITLOG
    executionOrder(cellfun(@isempty, dependencies)) = 1;
    visitLog = logical(executionOrder);
    
    fullDependencyList = cellstr(strings(size(calculations)));
    isDepChain = false(size(calculations));
    % While any Calculations are left unvisited (i.e. we have not set its EXECUTIONORDER),
    % continue to visit the unvisited Calculations
    while any(~visitLog)
        k = find(~visitLog, 1);
        % Find the execution order and full dependency list for the unvisited Calculation
        % and all its unvisited dependencies
        [executionOrder, visitLog, fullDependencyList, isDepChain] = visit(calculations, dependencies, calcID, dependID, executionOrder, k, visitLog, fullDependencyList, isDepChain);
    end
    fullDependencyList = cellfun(@unique, fullDependencyList, 'UniformOutput', false);
end

function [executionOrder, visitLog, fullDependList, isDepChain] = visit(calculations, dependencies, calcID, dependID, executionOrder, whichCalc, visitLog, fullDependList, isDepChain)
    
    isDepChain(whichCalc) = true;
    % If we have visited a Calculation and its execution order is still 0, this
    % Calculation forms part of a Circular reference. All Calculations in this circular
    % chain will be marked with a NaN.
    if visitLog(whichCalc) && (executionOrder(whichCalc) == 0)
        executionOrder(whichCalc) = NaN;
        
    % If we have not visited a Calculation before, mark it's VISITLOG entry true (visited),
    % extract its direct dependencies. For each direct dependency, visit the Calculation
    % and return the EXECUTIONORDER and FULLDEPENDLIST.
    elseif ~visitLog(whichCalc) && executionOrder(whichCalc) == 0
        visitLog(whichCalc) = true;
        directDependencies = dependencies{whichCalc};
        theseDependID = dependID{whichCalc};
        [~, directDependLoc] = ismember(theseDependID, calcID);
        
        for dep = 1:numel(directDependencies)
            thisDepCal = directDependencies(dep);
            thisDependID = theseDependID(dep);
            fullDependList{whichCalc} = [fullDependList{whichCalc}, thisDepCal];
            [~, thisCalc] = ismember(thisDependID, calcID);
            [executionOrder, visitLog, fullDependList, isDepChain] = visit(calculations, dependencies, calcID, dependID, executionOrder, thisCalc, visitLog, fullDependList, isDepChain);
            fullDependList{whichCalc} = [fullDependList{whichCalc}, fullDependList{thisCalc}];
        end
        % Once all of the Calculations in the direct dependencies list have been visited,
        % calculate this Calculation's EXECUTIONORDER. EXECUTIONORDER is 1 + the maximum of
        % the Dependencies' EXECUTIONORDERs, inculding NaN to ensure that circular references
        % are accounted for.
        executionOrder(whichCalc) = max(executionOrder(directDependLoc), [], 'includenan') + 1;
    end
end
function id = getDependentCalculationID(calculation)
    
    if ~isempty(calculation)
        id = [calculation.CalculationID];
    else
        id = [];
    end
end