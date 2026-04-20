function isDisabled = isCalculationDisabled(calculationState)
    %ISCALCULATIONACTIVE Checks CALCULATIONSTATE of a given calculation/s to
    %see if it is active.

    arguments
        calculationState (1, :) cce.CalculationState
    end

    disabledStates =  [cce.CalculationState.Disabled, cce.CalculationState.SystemDisabled];

    isDisabled = ismember(calculationState, disabledStates);
end