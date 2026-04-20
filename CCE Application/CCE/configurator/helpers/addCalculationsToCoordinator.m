function addCalculationsToCoordinator(calculations, coordinator)
    %ADDCALCULATIONSTOCOORDINATOR adds a list of Calculations to a Coordinator.
    %
    % Set the Calculations' CoordinatorID to the Coordinator's CoordinatorID.
    %
    % Set the Calculations' CalculationState to Idle.
    %
    % Increment the Coordinator's CalculationLoad by the number of Calculations added to it.
    
    id = coordinator.CoordinatorID;
    % If a Calculation is retired, do not set its ID to the CoordinatorID.
    idxRetired = [calculations.CalculationState] == cce.CalculationState.Retired;
    if any(~idxRetired)
        indNotRet = find(~idxRetired);
        for c = 1:sum(~idxRetired)
            calculations(indNotRet(c)).CoordinatorID = id;
            calculations(indNotRet(c)).commit();
        end
    end
    
    % If a Calculation is not in an active state, do not change its CalculationState.
    idxActive = cce.isCalculationActive([calculations.CalculationState]);
    if any(idxActive)
        indActive = find(idxActive);
        for c = 1:sum(idxActive)
            calculations(indActive(c)).CalculationState = cce.CalculationState.Idle;
            calculations(indNotRet(c)).commit();
        end
    end
    
    % Increase the Coordinator's CalculationLoad by the number of Calculations
    % successfully assigned to it.
    calcLoadIncrement = numel(calculations(~idxRetired));
    coordinator.CalculationLoad = coordinator.CalculationLoad + calcLoadIncrement;
    coordinator.commit();
end