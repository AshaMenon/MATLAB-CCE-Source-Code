function isActive = isCalculationActive(calculationState)
    %ISCALCULATIONACTIVE Checks CALCULATIONSTATE of a given calculation/s to
    %see if it is active.

    arguments
        calculationState (1, :) cce.CalculationState
    end

    inactiveStates =  [cce.CalculationState.Disabled, cce.CalculationState.Retired, ...
        cce.CalculationState.ConfigurationError, cce.CalculationState.SystemDisabled];

    isActive = ~ismember(calculationState, inactiveStates);
end