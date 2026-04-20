function addCalculationToCoordinator(coordinator, calculation)
    
    if calculation.CalculationState ~= cce.CalculationState.Retired
        coordinator.CalculationLoad = coordinator.CalculationLoad + 1;
        calculation.CoordinatorID = coordinator.CoordinatorID;
        if cce.isCalculationActive(calculation.CalculationState)
            calculation.CalculationState = string(cce.CalculationState.Idle);
        end
        coordinator.commit();
        calculation.commit();
    end
end