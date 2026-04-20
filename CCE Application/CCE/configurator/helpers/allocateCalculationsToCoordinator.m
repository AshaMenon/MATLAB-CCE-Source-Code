function [coordinators] = allocateCalculationsToCoordinator(calculations, fullDependencyList, isDepChain, idxUnassignedCalcs, coordinators, lifetime, logger)
    %ALLOCATECOORDINATOR allocates a calculation to a coordinator with matching
    %run-signature, i.e. same execution frequency, execution offset, and execution mode.
    
    %Remove Retired Calculations
    idxRetired = ismember([calculations.CalculationState],  cce.CalculationState.Retired);
    calculations = calculations(~idxRetired);
    fullDependencyList = fullDependencyList(~idxRetired);
    isDepChain = isDepChain(~idxRetired);
    idxUnassignedCalcs = idxUnassignedCalcs(~idxRetired);
    % If any Calculations are part of a dependency chain, determine the dependency chain
    % length and allocate the Calculations as a dependency chain accordingly
    if any(isDepChain)
        % Find all Calculations that for part of a Dependency Tree.
        dependencyCalculations = calculations(isDepChain);
        % Find the full dependency list for each Calculation in a Dependency Tree
        fullDependencyList = fullDependencyList(isDepChain);
        % Find the individual Dependency Trees and which Calculations belong to each Tree
        [whichTree, execFreqs] = findRelatedChains(dependencyCalculations, fullDependencyList);
        trees = unique(whichTree);
        numCalcsPerTree = splitapply(@numel, whichTree, whichTree);
        maxCalcLoads = arrayfun(@(x) getCalculationLoad(x), execFreqs);      
        
        idxShortChains = numCalcsPerTree <= maxCalcLoads;
        idxLongChains = numCalcsPerTree > maxCalcLoads;
        % For Dependency Trees with fewer Calculations than, treat each Tree as an atomic unit
        % and assign the Tree to the same Coordinator
        if any(idxShortChains)
            shortTrees = trees(idxShortChains);
            shortTreeCalcs = dependencyCalculations(ismember(whichTree, shortTrees));
            shortTreeNumber = whichTree(ismember(whichTree, shortTrees));
            [coordinators] = allocateShortDependencyTrees(shortTreeCalcs, shortTreeNumber, coordinators, lifetime, logger);
        end
        % Longer Dependency Trees are distributed across available + required Coordinators
        if any(idxLongChains)
            longTrees = trees(idxLongChains);
            longTreeCalcs = dependencyCalculations(ismember(whichTree, longTrees));
            longTreeNumber = whichTree(ismember(whichTree, longTrees));
            [coordinators] = allocateLongDependencyTrees(longTreeCalcs, longTreeNumber, coordinators, lifetime, logger);
        end
    end
    % Allocate all calculations on related chains to the same coordinator
    independentCalculations = calculations(~isDepChain);
    idxUnassignedCalcs = idxUnassignedCalcs(~isDepChain);
    [coordinators] = allocateIndependentCalculations(independentCalculations(idxUnassignedCalcs), coordinators, lifetime, logger);
end