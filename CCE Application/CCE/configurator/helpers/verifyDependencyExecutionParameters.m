function [calculationTree] = verifyDependencyExecutionParameters(calculationTree, fullDependencyList)
    %VERIFYDEPENDENCYEXECUTIONPARAMETERS checks that the Calculations in a dependency tree
    %are configured with compatable execution parameters
    %
    % ExecutionOffset: Calculations in the same dependency tree must have the same
    % execution offset
    %
    % ExecutionFrequency: Calculations must have an execution frequency that is a multiple
    % of all of their dependencies.    
    
    executionOrder = [calculationTree.ExecutionIndex];
    idxHigherOrder = executionOrder > 1;
    indHigherOrder = find(idxHigherOrder);
    
    offset = [calculationTree.ExecutionOffset];
    if any(offset ~= offset(1))
        for c = 1:sum(idxHigherOrder)
            %Set the Calculation to a Configuration Error
            calculationTree(indHigherOrder(c)).CalculationState = cce.CalculationState.ConfigurationError;
            %Add LastError
            calculationTree(indHigherOrder(c)).LastError = cce.CalculationErrorState.DepdendentOffsetNotSame;
        end
    end
    
    frequency = [calculationTree.ExecutionFrequency];
    frequency = num2cell(frequency);
    idxWrongFrequency = true(size(frequency));
    idxWrongFrequency(~idxHigherOrder) = false;
    idxWrongFrequency(idxHigherOrder) = cellfun(@(f, c) any(mod(f, [c.ExecutionFrequency]) ~= 0), frequency(idxHigherOrder), fullDependencyList(idxHigherOrder));
    if any(idxWrongFrequency)
        indWrongFrequency = find(idxWrongFrequency);
        for ind = indWrongFrequency
            calculationTree(ind).CalculationState = cce.CalculationState.ConfigurationError;
            %Add LastError
            calculationTree(ind).LastError = cce.CalculationErrorState.DepFrequenciesNotMultiple;
        end
    end
end